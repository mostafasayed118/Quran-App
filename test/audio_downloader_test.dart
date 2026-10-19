import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

import 'support/test_db.dart';

/// Serves a stream far larger than the content-length it declares.
class _LyingAdapter implements HttpClientAdapter {
  _LyingAdapter(this.chunks);

  final List<List<int>> chunks;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody(
      Stream.fromIterable(chunks.map(Uint8List.fromList)),
      200,
      headers: {
        Headers.contentLengthHeader: ['1000'],
        Headers.contentTypeHeader: ['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;
  late String base;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_audio_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  Future<AudioDownloader> serve(
    void Function(HttpRequest request) handler,
  ) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) => handler(req));
    base = 'http://127.0.0.1:${server.port}/';
    final row = await (db.select(db.reciters)).getSingle();
    final updated = row.copyWith(server: base);
    await (db.update(db.reciters)..where((r) => r.id.equals(row.id)))
        .write(RecitersCompanion(server: Value(updated.server)));
    return AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
  }

  tearDown(() {
    server.close(force: true);
  });

  test('download streams to file, reports progress, marks done', () async {
    final downloader = await serve((req) async {
      req.response.add(List<int>.generate(4096, (i) => i % 251));
      await req.response.close();
    });
    final reciter = await (db.select(db.reciters)).getSingle();
    final receivedTotal = <List<int>>[];
    final file = await downloader.downloadSurah(
      reciter: reciter,
      surahNumber: 2,
      onProgress: (received, total) => receivedTotal.add([received, total]),
    );

    expect(file.existsSync(), isTrue);
    expect(await file.length(), 4096);
    expect(receivedTotal, isNotEmpty);
    final statuses = await (db.select(db.downloads)
          ..where((d) => d.reciterId.equals('51-53')))
        .get();
    expect(statuses.single.status, 'done');
    expect(statuses.single.bytes, 4096);
    expect(await downloader.isDownloaded('51-53', 2), isTrue);
    expect(await downloader.downloadedPath('51-53', 2), file.path);
    expect(await downloader.downloadedPath('51-53', 1), isNull);
  });

  test('a stream far beyond its declared size is aborted as failed', () async {
    await serve((_) async {});
    final downloader = AudioDownloader(
      db,
      dio: Dio()
        ..httpClientAdapter = _LyingAdapter([
          for (var i = 0; i < 20; i++) List<int>.filled(100 * 1024, 7),
        ]),
      audioRootResolver: () async => tempRoot,
    );
    final reciter = await (db.select(db.reciters)).getSingle();

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 3),
      throwsA(isA<DownloadFailure>()),
    );

    final statuses = await (db.select(db.downloads)
          ..where((d) => d.reciterId.equals('51-53')))
        .get();
    expect(statuses.single.status, 'failed');
    expect(await downloader.isDownloaded('51-53', 3), isFalse);
  });

  test('server 404 marks failed and removes the partial file', () async {
    final downloader = await serve((req) async {
      req.response.statusCode = 404;
      await req.response.close();
    });
    final reciter = await (db.select(db.reciters)).getSingle();

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DioException>()),
    );

    final statuses = await (db.select(db.downloads)
          ..where((d) => d.reciterId.equals('51-53')))
        .get();
    expect(statuses.single.status, 'failed');
    expect(await downloader.isDownloaded('51-53', 1), isFalse);
  });

  group('maxAcceptedBytes (lying-host cap)', () {
    test('no content-length → the 64 MiB absolute ceiling', () {
      expect(AudioDownloader.maxAcceptedBytes(0), 64 << 20);
    });
    test('small declared length keeps the 2x + 64 KiB window', () {
      expect(AudioDownloader.maxAcceptedBytes(1000), 1000 * 2 + 65536);
    });
    test('a host lying large cannot raise the cap past the ceiling', () {
      expect(AudioDownloader.maxAcceptedBytes(1 << 30), 64 << 20);
    });
  });

  test('removeDownload deletes an in-root file and its row', () async {
    final downloader = await serve((req) async {
      req.response.add(List<int>.generate(1024, (i) => i % 251));
      await req.response.close();
    });
    final reciter = await (db.select(db.reciters)).getSingle();
    final file =
        await downloader.downloadSurah(reciter: reciter, surahNumber: 2);
    expect(file.existsSync(), isTrue);

    await downloader.removeDownload('51-53', 2);

    expect(file.existsSync(), isFalse);
    expect(await (db.select(db.downloads)).get(), isEmpty);
  });

  test('removeDownload never deletes outside the audio root (tampered row)',
      () async {
    final downloader = await serve((_) async {});
    final outside = File('${tempRoot.path}/outside.mp3')
      ..writeAsStringSync('x');
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '51-53',
          surahId: 9,
          status: 'done',
          path: outside.path,
          bytes: const Value(1),
        ));

    await downloader.removeDownload('51-53', 9);

    expect(outside.existsSync(), isTrue);
    expect(await (db.select(db.downloads)).get(), isEmpty);
  });
}
