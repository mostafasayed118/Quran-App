import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

/// 100 deterministic bytes: byte i has the value i.
final Uint8List _payload =
    Uint8List.fromList(List<int>.generate(100, (i) => i));

const String _rowId = '51-53';

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_audio_resume');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: _rowId,
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    await server.close(force: true);
  });

  Future<AudioDownloader> serve(
    Future<void> Function(HttpRequest request, int call) handler, {
    Duration retryDelay = const Duration(seconds: 3),
  }) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    var calls = 0;
    server.listen((req) {
      calls++;
      handler(req, calls);
    });
    final row = await (db.select(db.reciters)).getSingle();
    await (db.update(db.reciters)..where((r) => r.id.equals(row.id))).write(
      RecitersCompanion(
        server: Value('http://127.0.0.1:${server.port}/'),
      ),
    );
    return AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
      retryDelay: retryDelay,
    );
  }

  Future<ReciterRow> reciter() => (db.select(db.reciters)).getSingle();

  /// The exact path the downloader writes to, so a test can leave a prefix.
  Future<File> partFile(int surah) async {
    final folder = Directory(
        '${tempRoot.path}${Platform.pathSeparator}${AudioDownloader.audioFolderName}${Platform.pathSeparator}$_rowId');
    await folder.create(recursive: true);
    return File(
        '${folder.path}${Platform.pathSeparator}${surahAudioFileName(surah)}.part');
  }

  test('a stored prefix resumes with a Range request (206)', () async {
    String? range;
    final downloader = await serve((req, _) async {
      range = req.headers.value(HttpHeaders.rangeHeader);
      req.response.statusCode = HttpStatus.partialContent;
      req.response.headers
        ..contentType = ContentType('audio', 'mpeg')
        ..set(HttpHeaders.contentRangeHeader, 'bytes 40-99/100')
        ..contentLength = 60;
      req.response.add(_payload.sublist(40));
      await req.response.close();
    });

    final part = await partFile(1);
    await part.writeAsBytes(_payload.sublist(0, 40));

    final file = await downloader.downloadSurah(
      reciter: await reciter(),
      surahNumber: 1,
    );

    expect(range, 'bytes=40-', reason: 'the prefix must be offered back');
    expect(await file.length(), 100);
    expect(await file.readAsBytes(), _payload);
    expect(await part.exists(), isFalse, reason: 'the part is promoted');
  });

  test('a host that ignores Range restarts cleanly (200)', () async {
    final downloader = await serve((req, _) async {
      // Deliberately ignores the Range header and serves the whole file.
      req.response.statusCode = HttpStatus.ok;
      req.response.headers
        ..contentType = ContentType('audio', 'mpeg')
        ..contentLength = 100;
      req.response.add(_payload);
      await req.response.close();
    });

    final part = await partFile(1);
    await part.writeAsBytes(_payload.sublist(0, 40));

    final file = await downloader.downloadSurah(
      reciter: await reciter(),
      surahNumber: 1,
    );

    expect(await file.length(), 100);
    expect(
      await file.readAsBytes(),
      _payload,
      reason: 'a 200 body must replace the prefix, never be appended to it',
    );
  });

  test('a transient failure is retried once and resumes', () async {
    final ranges = <String?>[];
    final downloader = await serve(
      (req, call) async {
        ranges.add(req.headers.value(HttpHeaders.rangeHeader));
        if (call == 1) {
          req.response.statusCode = HttpStatus.internalServerError;
          await req.response.close();
          return;
        }
        final from =
            req.headers.value(HttpHeaders.rangeHeader) == null ? 0 : 40;
        req.response.statusCode =
            from > 0 ? HttpStatus.partialContent : HttpStatus.ok;
        req.response.headers
          ..contentType = ContentType('audio', 'mpeg')
          ..contentLength = 100 - from;
        if (from > 0) {
          req.response.headers
              .set(HttpHeaders.contentRangeHeader, 'bytes $from-99/100');
        }
        req.response.add(_payload.sublist(from));
        await req.response.close();
      },
      retryDelay: Duration.zero,
    );

    final part = await partFile(1);
    await part.writeAsBytes(_payload.sublist(0, 40));

    final file = await downloader.downloadSurah(
      reciter: await reciter(),
      surahNumber: 1,
    );

    expect(ranges, hasLength(2), reason: 'one failure + one resume attempt');
    expect(ranges.first, 'bytes=40-');
    expect(ranges.last, 'bytes=40-');
    expect(await file.readAsBytes(), _payload);
  });

  test('a 416 discards the unusable prefix and downloads from zero', () async {
    var calls = 0;
    var secondHasRange = true;
    final downloader = await serve(
      (req, call) async {
        calls = call;
        if (call == 1) {
          secondHasRange = req.headers.value(HttpHeaders.rangeHeader) != null;
          req.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          await req.response.close();
          return;
        }
        secondHasRange = req.headers.value(HttpHeaders.rangeHeader) != null;
        req.response.statusCode = HttpStatus.ok;
        req.response.headers
          ..contentType = ContentType('audio', 'mpeg')
          ..contentLength = 100;
        req.response.add(_payload);
        await req.response.close();
      },
      retryDelay: Duration.zero,
    );

    final part = await partFile(1);
    // A prefix longer than the (now smaller) resource.
    await part.writeAsBytes(Uint8List(200));

    final file = await downloader.downloadSurah(
      reciter: await reciter(),
      surahNumber: 1,
    );

    expect(calls, 2);
    expect(
      secondHasRange,
      isFalse,
      reason: 'the 416 must delete the part so the retry starts from zero',
    );
    expect(await file.readAsBytes(), _payload);
  });
}
