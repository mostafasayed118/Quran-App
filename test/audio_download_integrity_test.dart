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
final Uint8List _payload = Uint8List.fromList(
  List<int>.generate(100, (i) => i),
);

const String _rowId = '51-53';

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_audio_integrity');
    await db
        .into(db.reciters)
        .insert(
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
    Duration retryDelay = Duration.zero,
  }) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    var calls = 0;
    server.listen((req) {
      calls++;
      handler(req, calls);
    });
    final row = await (db.select(db.reciters)).getSingle();
    await (db.update(db.reciters)..where((r) => r.id.equals(row.id))).write(
      RecitersCompanion(server: Value('http://127.0.0.1:${server.port}/')),
    );
    return AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
      retryDelay: retryDelay,
    );
  }

  Future<File> partFile(int surah) async {
    final folder = Directory(
      '${tempRoot.path}${Platform.pathSeparator}${AudioDownloader.audioFolderName}${Platform.pathSeparator}$_rowId',
    );
    await folder.create(recursive: true);
    return File(
      '${folder.path}${Platform.pathSeparator}${surahAudioFileName(surah)}.part',
    );
  }

  test(
    'a 206 without a total size drops the prefix and restarts from zero',
    () async {
      final part = await partFile(1);
      await part.writeAsBytes(_payload.sublist(0, 40));
      await File('${part.path}.validator').writeAsString('"v1"');
      final ranges = <String?>[];

      final downloader = await serve((req, call) async {
        ranges.add(req.headers.value(HttpHeaders.rangeHeader));
        if (call == 1) {
          req.response.statusCode = HttpStatus.partialContent;
          req.response.headers
            ..contentType = ContentType('audio', 'mpeg')
            ..set(HttpHeaders.contentRangeHeader, 'bytes 40-99/*')
            ..contentLength = 60;
          req.response.add(_payload.sublist(40));
        } else {
          req.response.statusCode = HttpStatus.ok;
          req.response.headers
            ..contentType = ContentType('audio', 'mpeg')
            ..contentLength = _payload.length;
          req.response.add(_payload);
        }
        await req.response.close();
      });

      final file = await downloader.downloadSurah(
        reciter: await (db.select(db.reciters)).getSingle(),
        surahNumber: 1,
      );

      expect(
        await file.readAsBytes(),
        _payload,
        reason: 'the unknown-total prefix must not be appended to a full file',
      );
      expect(
        ranges,
        hasLength(2),
        reason: 'the first attempt must fail so the retry starts over',
      );
      expect(ranges.first, 'bytes=40-');
      expect(
        ranges.last,
        isNull,
        reason: 'the retry must ask for the whole file, not another range',
      );
      expect(await part.exists(), isFalse);
    },
  );

  test('a done row over an empty file is not a download', () async {
    final file = File('${tempRoot.path}${Platform.pathSeparator}empty.mp3');
    await file.writeAsBytes(<int>[]);
    await db
        .into(db.downloads)
        .insert(
          DownloadsCompanion.insert(
            reciterId: _rowId,
            surahId: 1,
            status: 'done',
            path: file.path,
          ),
        );

    final downloader = AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
    expect(await downloader.isDownloaded(_rowId, 1), isFalse);

    await file.writeAsBytes(<int>[1]);
    expect(await downloader.isDownloaded(_rowId, 1), isTrue);
  });

  test('a 200 answer to a validated resume rewrites from zero', () async {
    final part = await partFile(1);
    // A prefix that must not survive: 40 bytes of 0xFF, not the payload.
    await part.writeAsBytes(Uint8List(40)..fillRange(0, 40, 0xFF));
    await File('${part.path}.validator').writeAsString('"old"');
    String? ifRange;

    final downloader = await serve((req, _) async {
      ifRange = req.headers.value(HttpHeaders.ifRangeHeader);
      // The validator no longer matches: the host serves the whole file.
      req.response.statusCode = HttpStatus.ok;
      req.response.headers
        ..contentType = ContentType('audio', 'mpeg')
        ..set(HttpHeaders.etagHeader, '"new"')
        ..contentLength = _payload.length;
      req.response.add(_payload);
      await req.response.close();
    });

    final file = await downloader.downloadSurah(
      reciter: await (db.select(db.reciters)).getSingle(),
      surahNumber: 1,
    );

    expect(ifRange, '"old"');
    expect(
      await file.readAsBytes(),
      _payload,
      reason: 'a 200 body must replace the stale prefix, never be appended',
    );
  });

  test('a prefix with no validator is discarded before the request', () async {
    final part = await partFile(1);
    await part.writeAsBytes(Uint8List(40));
    String? range;

    final downloader = await serve((req, _) async {
      range = req.headers.value(HttpHeaders.rangeHeader);
      req.response.statusCode = HttpStatus.ok;
      req.response.headers
        ..contentType = ContentType('audio', 'mpeg')
        ..contentLength = _payload.length;
      req.response.add(_payload);
      await req.response.close();
    });

    final file = await downloader.downloadSurah(
      reciter: await (db.select(db.reciters)).getSingle(),
      surahNumber: 1,
    );

    expect(
      range,
      isNull,
      reason: 'an unverifiable prefix must not be offered back',
    );
    expect(await file.readAsBytes(), _payload);
  });
}
