import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

class _FullDiskDownloader extends AudioDownloader {
  _FullDiskDownloader(super.db)
      : super(audioRootResolver: () async => Directory.systemTemp);

  bool fail = true;

  @override
  Future<void> reconcileOnStart() async {}

  @override
  Future<List<Download>> listDone() async => const <Download>[];

  @override
  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    if (fail) throw DownloadFailure.outOfSpace();
    return File('${Directory.systemTemp.path}/fake-$surahNumber.mp3');
  }
}

void main() {
  late AppDatabase db;
  late _FullDiskDownloader downloader;
  late DownloadsCubit cubit;

  setUp(() async {
    db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: 'row-1',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1',
            surahTotal: 1,
          ),
        );
    downloader = _FullDiskDownloader(db);
    cubit = DownloadsCubit(
      downloader: downloader,
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
  });

  test('a full disk raises the flag and a successful retry clears it',
      () async {
    await cubit.enqueue('row-1', 1);

    expect(cubit.state.outOfSpace, isTrue);
    expect(cubit.state.items['row-1-1']?.status, DownloadStatus.failed);

    downloader.fail = false;
    await cubit.enqueue('row-1', 1);

    expect(cubit.state.items['row-1-1']?.status, DownloadStatus.done);
    expect(cubit.state.outOfSpace, isFalse,
        reason: 'the retry proved the device has space again');
  });

  test('dismissing the warning leaves the failed row retriable', () async {
    await cubit.enqueue('row-1', 1);
    expect(cubit.state.outOfSpace, isTrue);

    cubit.dismissOutOfSpace();

    expect(cubit.state.outOfSpace, isFalse);
    expect(cubit.state.items['row-1-1']?.status, DownloadStatus.failed);
  });
}
