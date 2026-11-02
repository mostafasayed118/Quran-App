import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

/// A downloader whose deletion fails for exactly one surah.
class _FailingRemoveDownloader extends AudioDownloader {
  _FailingRemoveDownloader(
    super.db, {
    super.audioRootResolver,
    required this.failFor,
  });

  final int failFor;

  @override
  Future<void> removeDownload(String rowId, int surahNumber) {
    if (surahNumber == failFor) {
      return Future<void>.error(StateError('remove failed'));
    }
    return super.removeDownload(rowId, surahNumber);
  }
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_downloads_summary');
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

  Future<void> insertDone(int surahNumber, int bytes) async {
    await db.into(db.downloads).insert(
          DownloadsCompanion.insert(
            reciterId: '51-53',
            surahId: surahNumber,
            status: 'done',
            path: '${tempRoot.path}/audio/51-53/'
                '${surahNumber.toString().padLeft(3, '0')}.mp3',
            bytes: Value(bytes),
          ),
        );
  }

  DownloadsCubit newCubit({AudioDownloader? downloader}) {
    final cubit = DownloadsCubit(
      downloader: downloader ??
          AudioDownloader(db, audioRootResolver: () async => tempRoot),
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('summary sums the installed rows', () async {
    await insertDone(1, 1048576); // 1 MB
    await insertDone(2, 2097152); // 2 MB
    await insertDone(3, 3145728); // 3 MB

    final summary = await newCubit().summary();

    expect(summary.count, 3);
    expect(summary.bytes, 6291456, reason: '1 + 2 + 3 MB');
  });

  test('summary of an empty registry is zero', () async {
    final summary = await newCubit().summary();

    expect(summary.count, 0);
    expect(summary.bytes, 0);
  });

  test('removeAll deletes every installed row', () async {
    await insertDone(1, 1048576);
    await insertDone(2, 2097152);
    await insertDone(3, 3145728);
    final cubit = newCubit();

    await cubit.removeAll();

    expect(await db.select(db.downloads).get(), isEmpty);
    expect(await cubit.installed(), isEmpty);
  });

  test('removeAll stops at the first failure and keeps the earlier removals',
      () async {
    await insertDone(1, 1048576);
    await insertDone(2, 2097152);
    await insertDone(3, 3145728);
    final cubit = newCubit(
      downloader: _FailingRemoveDownloader(
        db,
        audioRootResolver: () async => tempRoot,
        failFor: 2,
      ),
    );

    await expectLater(cubit.removeAll(), throwsA(isA<StateError>()));

    final left = await db.select(db.downloads).get();
    expect(left.map((row) => row.surahId), [2, 3],
        reason: 'the first row is gone, the failed row and the rest stay');
  });
}
