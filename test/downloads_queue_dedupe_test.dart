import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

const ReciterRow _row = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1',
  surahTotal: 114,
);

/// Catalog seam with a fixed row (no database reads needed).
class _StaticReciters extends ReciterRepository {
  _StaticReciters(super.db);

  @override
  Future<ReciterRow?> byId(String rowId) async => _row;
}

/// Downloader whose transfers hang on a test-owned gate, so the queue window
/// is observed deterministically.
class _ControllableDownloader extends AudioDownloader {
  _ControllableDownloader(super.db);

  int downloadCalls = 0;
  final List<Completer<void>> gates = <Completer<void>>[];

  @override
  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    downloadCalls += 1;
    final gate = Completer<void>();
    gates.add(gate);
    final token = cancelToken;
    if (token != null) {
      unawaited(token.whenCancel.then((_) {
        if (!gate.isCompleted) gate.completeError(StateError('cancelled'));
      }));
    }
    await gate.future;
    return File('${reciter.id}-$surahNumber.mp3');
  }

  @override
  Future<void> removeDownload(String rowId, int surahNumber) async {}
}

void main() {
  late AppDatabase db;
  late _ControllableDownloader downloader;
  late DownloadsCubit cubit;

  setUp(() {
    db = newTestDb();
    downloader = _ControllableDownloader(db);
    cubit =
        DownloadsCubit(downloader: downloader, reciters: _StaticReciters(db));
    addTearDown(cubit.close);
  });

  Future<void> waitForDownloads(int count) async {
    var spins = 0;
    while (downloader.gates.length < count) {
      if (spins++ > 200) fail('download never started');
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('two rapid enqueue calls for the same key download once', () async {
    final first = cubit.enqueue('51-53', 1);
    final second = cubit.enqueue('51-53', 1);

    await waitForDownloads(1);
    expect(downloader.downloadCalls, 1,
        reason: 'the queued-state guard must reject the second call');

    downloader.gates.single.complete();
    await first.timeout(const Duration(seconds: 10));
    await second.timeout(const Duration(seconds: 10));

    expect(downloader.downloadCalls, 1);
    expect(cubit.state.items['51-53-1']?.status, DownloadStatus.done);
  });

  test('cancelling the active download leaves no queued duplicate to restart',
      () async {
    final first = cubit.enqueue('51-53', 1);
    await waitForDownloads(1);

    // A second request while the key is active must be rejected, not queued.
    await cubit.enqueue('51-53', 1).timeout(const Duration(seconds: 10));
    expect(downloader.downloadCalls, 1);

    final cleared =
        cubit.stream.firstWhere((s) => !s.items.containsKey('51-53-1'));
    await cubit.cancelDownload('51-53', 1);
    await cleared.timeout(const Duration(seconds: 10));
    await first.timeout(const Duration(seconds: 10));

    expect(downloader.downloadCalls, 1,
        reason: 'the cancelled surah must not restart from a queued duplicate');
    expect(cubit.state.items.containsKey('51-53-1'), isFalse);
  });
}
