import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

class _HoldDownloader extends AudioDownloader {
  // ignore: use_super_parameters
  _HoldDownloader(AppDatabase db)
      : super(db, audioRootResolver: () async => Directory.systemTemp);

  final gate = Completer<void>();
  final calls = <int>[];

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
    calls.add(surahNumber);
    await gate.future;
    return File('${Directory.systemTemp.path}/fake-$surahNumber.mp3');
  }
}

void main() {
  test('enqueueAll queues only the missing surahs and is idempotent', () async {
    final db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: 'row-1',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1,2,3',
            surahTotal: 3,
          ),
        );
    final downloader = _HoldDownloader(db);
    final cubit = DownloadsCubit(
      downloader: downloader,
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);

    final first = await cubit.enqueueAll('row-1', [1, 2, 3]);
    expect(first, 3);
    expect(
      cubit.state.items.values.map((item) => item.status),
      everyElement(DownloadStatus.queued),
    );

    final second = await cubit.enqueueAll('row-1', [1, 2, 3]);
    expect(second, 0);
    expect(cubit.state.items, hasLength(3));

    final third = await cubit.enqueueAll('row-1', [1, 2, 3, 4]);
    expect(third, 1);
    expect(cubit.state.items, hasLength(4));

    downloader.gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
