import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audio_downloader.dart';
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
    final rows = await _downloader.listDone();
    var items = state.items;
    for (final row in rows) {
      final key = '${row.reciterId}-${row.surahId}';
      items = {...items, key: const DownloadItem(status: 'done')};
    }
    if (isClosed) return;
    emit(state.copyWith(items: items));
  }

  /// Removes an installed download through the existing
  /// [AudioDownloader.removeDownload] (file + DB row) and drops its entry
  /// from the state so rows re-render — the delete affordance's refresh path
  /// (UX-FIX 2; mirrors LibraryCubit.uninstall, no new state machinery).
  Future<void> removeDone(String rowId, int surahNumber) async {
    await _downloader.removeDownload(rowId, surahNumber);
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
        (current.status == 'downloading' || current.status == 'done')) {
      return;
    }
    if (_queue.any((task) => task.$1 == rowId && task.$2 == surahNumber)) {
      return;
    }
    _queue.add((rowId, surahNumber));
    emit(state.copyWith(
      items: {
        ...state.items,
        key: const DownloadItem(status: 'queued'),
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
        final reciter = await _reciters.byId(rowId);
        if (reciter == null) {
          await _setFailed(key);
          continue;
        }
        if (isClosed) return;
        emit(_bump(key, status: 'downloading'));
        try {
          await _downloader.downloadSurah(
            reciter: reciter,
            surahNumber: surahNumber,
            onProgress: (received, total) {
              if (isClosed) return;
              emit(_bump(key,
                  status: 'downloading', received: received, total: total));
            },
          );
          if (isClosed) return;
          emit(_bump(key, status: 'done'));
        } on Object {
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
    emit(_bump(key, status: 'failed'));
  }

  DownloadsState _bump(String key,
      {required String status, int received = 0, int total = 0}) {
    final current = state.items[key] ?? const DownloadItem();
    return state.copyWith(
      items: {
        ...state.items,
        key: current.copyWith(status: status, received: received, total: total),
      },
    );
  }
}
