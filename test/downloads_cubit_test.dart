import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_queue_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2,3',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
    await db.close();
  });

  test('enqueue drains strictly sequentially and marks done', () async {
    final order = <String>[];
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      order.add(req.uri.path);
      req.response.add(List<int>.filled(64, 1));
      req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final base = 'http://127.0.0.1:${server.port}/';
    await (db.update(db.reciters)).write(RecitersCompanion(server: Value(base)));
    final repo = ReciterRepository(db);
    final downloader = AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
    final cubit = DownloadsCubit(downloader: downloader, reciters: repo);
    addTearDown(cubit.close);

    // Broadcast stream: subscribe BEFORE the drains run, or emissions are lost.
    final bothDone = cubit.stream.firstWhere((s) =>
        s.items['51-53-1']?.status == 'done' &&
        s.items['51-53-2']?.status == 'done');
    await cubit.enqueue('51-53', 1);
    await cubit.enqueue('51-53', 2);
    await bothDone;

    expect(order, ['/001.mp3', '/002.mp3'],
        reason: 'queue is strictly sequential');
  });

  test('failed task does not stall the queue', () async {
    var failNext = true;
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      if (failNext) {
        failNext = false;
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.add(List<int>.filled(32, 1));
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final base = 'http://127.0.0.1:${server.port}/';
    await (db.update(db.reciters)).write(RecitersCompanion(server: Value(base)));
    final repo = ReciterRepository(db);
    final downloader = AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
    final cubit = DownloadsCubit(downloader: downloader, reciters: repo);
    addTearDown(cubit.close);

    // Broadcast stream: subscribe BEFORE the drains run, or emissions are lost.
    final settled = cubit.stream.firstWhere((s) =>
        s.items['51-53-1']?.status == 'failed' &&
        s.items['51-53-2']?.status == 'done');
    await cubit.enqueue('51-53', 1); // will fail
    await cubit.enqueue('51-53', 2); // must still complete
    await settled;
  });
}
