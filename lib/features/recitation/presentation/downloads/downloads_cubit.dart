import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audio_downloader.dart';
import '../../data/download_status.dart';
import '../../data/recitation_keys.dart';
import '../../data/reciter_repository.dart';
import 'downloads_state.dart';

/// The downloads screen: the per-surah download queue and the done rows.
class DownloadsCubit extends Cubit<DownloadsState> {
  /// Creates the cubit with the downloader and the reciter catalog.
  ///
  /// No work starts here: the screen calls [refreshDone] to list the
  /// already-downloaded rows and [enqueue] to queue new ones.
  DownloadsCubit({
    required AudioDownloader downloader,
    required ReciterRepository reciters,
  })  : _downloader = downloader,
        _reciters = reciters,
        super(const DownloadsState());

  final AudioDownloader _downloader;
  final ReciterRepository _reciters;

  /// One-shot startup reconciliation. `enqueue`/`refreshDone` await it so a
  /// new download can never have its `.part` swept as an orphan.
  Future<void>? _reconcile;
  final List<(String, int)> _queue = <(String, int)>[];

  Future<void> _ensureReconciled() =>
      _reconcile ??= _reconcileDownloader(_downloader);

  static Future<void> _reconcileDownloader(AudioDownloader downloader) async {
    try {
      await downloader.reconcileOnStart();
    } on Object catch (error, stackTrace) {
      dev.log('download reconciliation failed',
          name: 'quran_yahdi/downloads', error: error, stackTrace: stackTrace);
    }
  }

  bool _draining = false;
  (String, int)? _active;
  CancelToken? _activeToken;

  String _key(String rowId, int surahNumber) => downloadKey(rowId, surahNumber);

  /// Re-reads the finished downloads and merges them into the state.
  ///
  /// A failure is soft: the screen keeps rendering, the done rows simply
  /// stay missing until the next refresh.
  Future<void> refreshDone() async {
    await _ensureReconciled();
    try {
      final rows = await _downloader.listDone();
      final items = {
        ...state.items,
        for (final row in rows)
          downloadKey(row.reciterId, row.surahId):
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
  ///
  /// Returns `true` when the file and row were removed and the entry was
  /// dropped, `false` when the removal failed and the entry therefore stays.
  Future<bool> removeDone(String rowId, int surahNumber) async {
    try {
      await _downloader.removeDownload(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      dev.log('download remove failed',
          name: 'quran_yahdi/downloads', error: error, stackTrace: stackTrace);
      return false;
    }
    if (isClosed) return false;
    emit(state.copyWith(items: {
      for (final entry in state.items.entries)
        if (entry.key != downloadKey(rowId, surahNumber))
          entry.key: entry.value,
    }));
    return true;
  }

  /// Queues the download of one surah for one reciter.
  ///
  /// A row that is already queued, downloading, done, or currently active is
  /// ignored.
  Future<void> enqueue(String rowId, int surahNumber) async {
    final key = _key(rowId, surahNumber);
    final current = state.items[key];
    if (current != null &&
        (current.status == DownloadStatus.queued ||
            current.status == DownloadStatus.downloading ||
            current.status == DownloadStatus.done)) {
      return;
    }
    if (_queue.any((task) => task.$1 == rowId && task.$2 == surahNumber)) {
      return;
    }
    final active = _active;
    if (active != null && active.$1 == rowId && active.$2 == surahNumber) {
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
      // Reconcile before the first transfer, but after the synchronous
      // queued-state emission in enqueue (the queue must react immediately).
      await _ensureReconciled();
      while (_queue.isNotEmpty && !isClosed) {
        final (rowId, surahNumber) = _queue.first;
        _queue.removeAt(0);
        final key = _key(rowId, surahNumber);
        final token = CancelToken();
        _active = (rowId, surahNumber);
        _activeToken = token;
        try {
          final reciter = await _reciters.byId(rowId);
          if (isClosed) return;
          if (reciter == null) {
            await _setFailed(key);
            continue;
          }
          emit(_bump(key, status: DownloadStatus.downloading));
          await _downloader.downloadSurah(
            reciter: reciter,
            surahNumber: surahNumber,
            cancelToken: token,
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
          if (token.isCancelled) {
            await _dropCancelled(rowId, surahNumber, key);
          } else {
            dev.log('surah download failed',
                name: 'quran_yahdi/downloads',
                error: error,
                stackTrace: stackTrace);
            if (isClosed) return;
            await _setFailed(key);
          }
        } finally {
          if (identical(_activeToken, token)) _activeToken = null;
          if (_active == (rowId, surahNumber)) _active = null;
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Cancels a queued or in-flight download: a queued task leaves the queue,
  /// the active task is aborted through its [CancelToken]. Either way the
  /// state entry is dropped and the registry row + partial file are cleaned
  /// up (mirrors [removeDone]). Idle or done rows are a no-op.
  Future<void> cancelDownload(String rowId, int surahNumber) async {
    final key = _key(rowId, surahNumber);
    final status = state.items[key]?.status;
    if (status != DownloadStatus.queued &&
        status != DownloadStatus.downloading) {
      return;
    }
    // Drop every queued duplicate first: a cancelled surah must never restart
    // from a stale queue entry for the same key.
    _queue.removeWhere((task) => task.$1 == rowId && task.$2 == surahNumber);
    final active = _active;
    if (active != null && active.$1 == rowId && active.$2 == surahNumber) {
      _activeToken?.cancel('cancelled by user');
      return; // the in-flight catch drops the entry and cleans up.
    }
    _removeEntry(key); // queued or untracked entry: drop it from the map.
  }

  Future<void> _dropCancelled(String rowId, int surahNumber, String key) async {
    try {
      await _downloader.removeDownload(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      dev.log('cancelled download cleanup failed',
          name: 'quran_yahdi/downloads', error: error, stackTrace: stackTrace);
    }
    _removeEntry(key);
  }

  void _removeEntry(String key) {
    if (isClosed) return;
    if (!state.items.containsKey(key)) return;
    final items = {...state.items}..remove(key);
    emit(state.copyWith(items: items));
  }

  Future<void> _setFailed(String key) async {
    if (isClosed) return;
    // The failed status in the DB is owned by the downloader; mirror in state.
    emit(_bump(key, status: DownloadStatus.failed));
  }

  /// Cancels the in-flight download and drops the pending queue.
  @override
  Future<void> close() async {
    _activeToken?.cancel('cubit closed');
    _queue.clear();
    await super.close();
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
