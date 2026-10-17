import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audio_downloader.dart';
import '../../data/download_status.dart';
import '../../data/reciter_repository.dart';
import 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  DownloadsCubit({
    required AudioDownloader downloader,
    required ReciterRepository reciters,
  })  : _downloader = downloader,
        _reciters = reciters,
        super(const DownloadsState());

  final AudioDownloader _downloader;
  final ReciterRepository _reciters;
  final List<(String, int)> _queue = <(String, int)>[];
  bool _draining = false;

  String _key(String rowId, int surahNumber) => '$rowId-$surahNumber';

  Future<void> refreshDone() async {
    try {
      final rows = await _downloader.listDone();
      final items = {
        ...state.items,
        for (final row in rows)
          '${row.reciterId}-${row.surahId}':
              const DownloadItem(status: DownloadStatus.done),
      };
      if (isClosed) return;
      emit(state.copyWith(items: items));
    } on Object catch (error, stackTrace) {
      // Soft failure: the caller's screen keeps rendering; done rows are
      // just missing until the next refresh.
      dev.log('downloads refresh failed',
          name: 'quran_yahdi/downloads', error: error, stackTrace: stackTrace);
    }
  }

  /// Removes an installed download through the existing
  /// [AudioDownloader.removeDownload] (file + DB row) and drops its entry
  /// from the state so rows re-render — the delete affordance's refresh path
  /// (UX-FIX 2; mirrors LibraryCubit.uninstall, no new state machinery).
  Future<void> removeDone(String rowId, int surahNumber) async {
    try {
      await _downloader.removeDownload(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      dev.log('download remove failed',
          name: 'quran_yahdi/downloads', error: error, stackTrace: stackTrace);
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(items: {
      for (final entry in state.items.entries)
        if (entry.key != '$rowId-$surahNumber') entry.key: entry.value,
    }));
  }

  Future<void> enqueue(String rowId, int surahNumber) async {
    final key = _key(rowId, surahNumber);
    final current = state.items[key];
    if (current != null &&
        (current.status == DownloadStatus.downloading ||
            current.status == DownloadStatus.done)) {
      return;
    }
    if (_queue.any((task) => task.$1 == rowId && task.$2 == surahNumber)) {
      return;
    }
    _queue.add((rowId, surahNumber));
    emit(state.copyWith(
      items: {
        ...state.items,
        key: const DownloadItem(status: DownloadStatus.queued),
      },
    ));
    await _drain();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !isClosed) {
        final (rowId, surahNumber) = _queue.first;
        _queue.removeAt(0);
        final key = _key(rowId, surahNumber);
        try {
          final reciter = await _reciters.byId(rowId);
          if (reciter == null) {
            if (isClosed) return;
            await _setFailed(key);
            continue;
          }
          if (isClosed) return;
          emit(_bump(key, status: DownloadStatus.downloading));
          await _downloader.downloadSurah(
            reciter: reciter,
            surahNumber: surahNumber,
            onProgress: (received, total) {
              if (isClosed) return;
              emit(_bump(key,
                  status: DownloadStatus.downloading,
                  received: received,
                  total: total));
            },
          );
          if (isClosed) return;
          emit(_bump(key, status: DownloadStatus.done));
        } on Object catch (error, stackTrace) {
          dev.log('surah download failed',
              name: 'quran_yahdi/downloads',
              error: error,
              stackTrace: stackTrace);
          if (isClosed) return;
          await _setFailed(key);
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _setFailed(String key) async {
    // The failed status in the DB is owned by the downloader; mirror in state.
    emit(_bump(key, status: DownloadStatus.failed));
  }

  DownloadsState _bump(String key,
      {required DownloadStatus status, int received = 0, int total = 0}) {
    final current = state.items[key] ?? const DownloadItem();
    return state.copyWith(
      items: {
        ...state.items,
        key: current.copyWith(status: status, received: received, total: total),
      },
    );
  }
}
