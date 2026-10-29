import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pack_downloader.dart';
import 'hadith_state.dart';

/// Pages through an INSTALLED hadith pack with a fixed page size.
class HadithCubit extends Cubit<HadithState> {
  /// Creates the cubit for one installed pack; the constructor is
  /// side-effect free and does no work — [start] loads the first page.
  HadithCubit({
    required PackDownloader downloader,
    required String packId,
  })  : _downloader = downloader,
        _packId = packId,
        super(const HadithState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => _load(0);

  /// How many hadith rows one page holds.
  static const int pageSize = 10;

  final PackDownloader _downloader;
  final String _packId;
  bool _paging = false;

  Future<void> _load(int offset) async {
    if (_paging) return;
    _paging = true;
    try {
      List<(int, String)> items;
      var hasMore = false;
      String packTitle;
      String language;
      try {
        final rows = await _downloader.installedPacks();
        final row = rows.where((r) => r.packId == _packId).firstOrNull;
        packTitle = row?.title ?? _packId;
        language = row?.language ?? '';
        (items, hasMore) =
            await _downloader.hadithPage(_packId, offset, pageSize);
      } on Object catch (error, stackTrace) {
        dev.log('hadith load failed',
            name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
        if (isClosed) return;
        emit(const HadithState.failed());
        return;
      }
      if (isClosed) return;
      emit(HadithState.ready(
        packTitle: packTitle,
        language: language,
        items: items,
        offset: offset,
        hasMore: hasMore,
      ));
    } finally {
      _paging = false;
    }
  }

  /// Loads the next page; a no-op when the last page was reached.
  Future<void> next() {
    final s = state;
    if (s is! HadithReady || !s.hasMore) return Future.value();
    return _load(s.offset + pageSize);
  }

  /// Loads the previous page; a no-op on the first page.
  Future<void> prev() {
    final s = state;
    if (s is! HadithReady || s.offset <= 0) return Future.value();
    return _load(s.offset - pageSize);
  }
}
