import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_cancel_test');
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
  });

  Future<DownloadsCubit> buildCubit(String base) async {
    await (db.update(db.reciters))
        .write(RecitersCompanion(server: Value(base)));
    final cubit = DownloadsCubit(
      downloader: AudioDownloader(
        db,
        dio: Dio(),
        audioRootResolver: () async => tempRoot,
      ),
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('cancelling a queued task removes it and its state entry', () async {
    final requests = <String>[];
    final firstRequest = Completer<HttpRequest>();
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      requests.add(req.uri.path);
      if (!firstRequest.isCompleted) firstRequest.complete(req);
    });
    addTearDown(() async => server.close(force: true));
    final cubit = await buildCubit('http://127.0.0.1:${server.port}/');

    unawaited(cubit.enqueue('51-53', 1));
    await firstRequest.future; // task 1 is in flight and hung on the response

    unawaited(cubit.enqueue('51-53', 2));
    // The queued emission is synchronous inside enqueue.
    expect(cubit.state.items['51-53-2']?.status, DownloadStatus.queued);

    await cubit.cancelDownload('51-53', 2);

    expect(cubit.state.items.containsKey('51-53-2'), isFalse);
    expect(requests, ['/001.mp3'],
        reason: 'the cancelled queued task must never hit the server');

    final cleared =
        cubit.stream.firstWhere((s) => !s.items.containsKey('51-53-1'));
    await cubit.cancelDownload('51-53', 1);
    await cleared;
    expect(cubit.state.items.containsKey('51-53-1'), isFalse);
  });

  test(
      'cancelling the in-flight task aborts it, drops the entry and leaves '
      'no registry row or partial file', () async {
    final firstRequest = Completer<HttpRequest>();
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      if (!firstRequest.isCompleted) firstRequest.complete(req);
    });
    addTearDown(() async => server.close(force: true));
    final cubit = await buildCubit('http://127.0.0.1:${server.port}/');

    unawaited(cubit.enqueue('51-53', 1));
    await firstRequest.future;

    final cleared =
        cubit.stream.firstWhere((s) => !s.items.containsKey('51-53-1'));
    await cubit.cancelDownload('51-53', 1);
    await cleared;

    expect(cubit.state.items.containsKey('51-53-1'), isFalse);
    expect(await db.select(db.downloads).get(), isEmpty);
    final folder = Directory('${tempRoot.path}/audio/51-53');
    final leftovers = folder.existsSync()
        ? folder.listSync().whereType<File>().toList()
        : <File>[];
    expect(leftovers, isEmpty);
  });

  test('cancelDownload on an idle row is a no-op', () async {
    final cubit = await buildCubit('https://example.invalid/');

    await cubit.cancelDownload('51-53', 1);

    expect(cubit.state.items, isEmpty);
  });
}
