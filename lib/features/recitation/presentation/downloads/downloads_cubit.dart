import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audio_downloader.dart';
import '../../data/download_status.dart';
import '../../data/recitation_keys.dart';
import '../../data/reciter_repository.dart';
import 'downloads_state.dart';

/// One installed download with its display names resolved.
///
/// A read-side projection, not cubit state: the list is rebuilt from the
/// downloader on every read, so it never needs to ride the freezed state.
/// [reciterName] and [surahName] are empty when the catalog cannot resolve
/// them; the screen owns the localized fallback.
class InstalledDownload {
  /// Creates one row of the installed list.
  const InstalledDownload({
    required this.rowId,
    required this.surahNumber,
    required this.reciterName,
    required this.surahName,
    required this.bytes,
  });

  /// Reciter (moshaf) row id that owns the file.
  final String rowId;

  /// Surah number of the installed file.
  final int surahNumber;

  /// Display name of the reciter.
  final String reciterName;

  /// Display name of the surah.
  final String surahName;

  /// Size of the installed file in bytes.
  final int bytes;
}

/// How much space the installed downloads take, and in how many files.
///
/// Another read-side projection (see [InstalledDownload]) built on every
/// read: the registry is the owner, the cubit holds no copy.
class DownloadsSummary {
  /// Creates an aggregate of [count] files totalling [bytes].
  const DownloadsSummary({required this.count, required this.bytes});

  /// Number of installed files.
  final int count;

  /// Total size of the installed files, in bytes.
  final int bytes;
}

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
  DownloadCancelToken? _activeToken;

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

  /// The installed downloads, resolved for the downloads list.
  ///
  /// Reciter names come from [ReciterRepository.byId] and surah names from
  /// [ReciterRepository.surahNamesFor] — the same bundled catalog the reciter
  /// surahs screen reads. A failure propagates: the screen owns the error arm,
  /// unlike [refreshDone], which is a soft merge into the state.
  Future<List<InstalledDownload>> installed() async {
    await _ensureReconciled();
    final rows = await _downloader.listDone();
    if (rows.isEmpty) return const <InstalledDownload>[];
    final reciterNames = <String, String>{};
    for (final rowId in {for (final row in rows) row.reciterId}) {
      final reciter = await _reciters.byId(rowId);
      if (reciter != null) reciterNames[rowId] = reciter.reciterName.trim();
    }
    final surahNames = await _reciters.surahNamesFor(
      {for (final row in rows) row.surahId}.toList(growable: false),
    );
    final items = <InstalledDownload>[
      for (final row in rows)
        InstalledDownload(
          rowId: row.reciterId,
          surahNumber: row.surahId,
          reciterName: reciterNames[row.reciterId] ?? '',
          surahName: surahNames[row.surahId] ?? '',
          bytes: row.bytes,
        ),
    ];
    // A stable order keeps the list from reshuffling between refreshes.
    items.sort((a, b) {
      final byReciter = a.reciterName.compareTo(b.reciterName);
      return byReciter != 0
          ? byReciter
          : a.surahNumber.compareTo(b.surahNumber);
    });
    return items;
  }

  /// The count and total size of the installed downloads.
  ///
  /// Reads the registry directly instead of going through [installed]: the
  /// header needs only the numbers, not the resolved display names. A failure
  /// propagates so the screen can render its error pane.
  Future<DownloadsSummary> summary() async {
    await _ensureReconciled();
    final rows = await _downloader.listDone();
    var bytes = 0;
    for (final row in rows) {
      bytes += row.bytes;
    }
    return DownloadsSummary(count: rows.length, bytes: bytes);
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

  /// Removes every installed download, one [removeDone] per row.
  ///
  /// Stops at the first row that could not be removed and throws, so the
  /// screen shows its error pane. The rows removed before the failure stay
  /// removed, so a retry only touches what is left.
  Future<void> removeAll() async {
    for (final item in await installed()) {
      if (!await removeDone(item.rowId, item.surahNumber)) {
        throw StateError(
          'download removal failed for ${item.rowId}-${item.surahNumber}',
        );
      }
    }
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

  /// Queues every surah in [surahNumbers] that is not already queued,
  /// downloading or done.
  ///
  /// Returns the number of rows newly queued. The drain starts in the
  /// background so the caller can confirm immediately; a zero result means
  /// the whole set is already present or in flight.
  Future<int> enqueueAll(String rowId, Iterable<int> surahNumbers) async {
    await _ensureReconciled();
    final queued = <String, DownloadItem>{};
    for (final surahNumber in surahNumbers) {
      final key = _key(rowId, surahNumber);
      final current = state.items[key];
      if (current != null &&
          (current.status == DownloadStatus.queued ||
              current.status == DownloadStatus.downloading ||
              current.status == DownloadStatus.done)) {
        continue;
      }
      if (_queue.any((task) => task.$1 == rowId && task.$2 == surahNumber)) {
        continue;
      }
      final active = _active;
      if (active != null && active.$1 == rowId && active.$2 == surahNumber) {
        continue;
      }
      _queue.add((rowId, surahNumber));
      queued[key] = const DownloadItem(status: DownloadStatus.queued);
    }
    if (queued.isEmpty) return 0;
    emit(state.copyWith(items: {...state.items, ...queued}));
    unawaited(_drain());
    return queued.length;
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
        final token = DownloadCancelToken();
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
  /// the active task is aborted through its [DownloadCancelToken]. Either way the
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
