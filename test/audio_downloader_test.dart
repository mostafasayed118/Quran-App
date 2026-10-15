import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;
  late String base;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
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
    await db.close();
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
    final reciter =
        await (db.select(db.reciters)).getSingle();
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
}
