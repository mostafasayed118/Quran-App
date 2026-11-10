import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/hadith_personal.dart';
import '../../data/pack_downloader.dart';
import 'hadith_state.dart';

/// Pages through an INSTALLED hadith pack: browse, search and bookmarks.
class HadithCubit extends Cubit<HadithState> {
  /// Creates the cubit for one installed pack; the constructor is
  /// side-effect free and does no work — [start] loads the first page.
  HadithCubit({
    required PackDownloader downloader,
    required String packId,
    HadithBookmarkSource? bookmarks,
    HadithPositionSource? positions,
  })  : _downloader = downloader,
        _packId = packId,
        _bookmarks = bookmarks,
        _positions = positions,
        super(const HadithState.loading());

  /// Starts the route-scoped load at the saved position.
  Future<void> start() async {
    try {
      _bookmarked = await _bookmarks?.load(_packId) ?? <int>{};
    } on Object catch (error, stackTrace) {
      appLog('hadith bookmarks load failed',
          name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
    }
    var offset = 0;
    try {
      offset = await _positions?.load(_packId) ?? 0;
    } on Object catch (error, stackTrace) {
      appLog('hadith position load failed',
          name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
    }
    await _load(offset);
  }

  /// How many hadith rows one page holds.
  static const int pageSize = 10;

  final PackDownloader _downloader;
  final String _packId;
  final HadithBookmarkSource? _bookmarks;
  final HadithPositionSource? _positions;

  Set<int> _bookmarked = <int>{};
  String _query = '';
  bool _bookmarksOnly = false;
  bool _paging = false;

  /// Searches the installed pack; an empty query restores the browse pages.
  Future<void> search(String value) {
    final query = value.trim();
    _query = query;
    _bookmarksOnly = false;
    return _load(0, query: query, bookmarksOnly: false);
  }

  /// Clears the search and returns to the saved browse position.
  Future<void> clearSearch() => search('');

  /// Shows only the bookmarked hadiths (one page).
  Future<void> showBookmarks() {
    _query = '';
    _bookmarksOnly = true;
    return _load(0, query: '', bookmarksOnly: true);
  }

  /// Returns to the browse pages.
  Future<void> showBrowse() {
    _query = '';
    _bookmarksOnly = false;
    return _load(0, query: '', bookmarksOnly: false);
  }

  /// Toggles [number] in the bookmarked set and persists it.
  Future<void> toggleBookmark(int number) async {
    final previous = _bookmarked;
    final next = <int>{..._bookmarked};
    if (!next.remove(number)) next.add(number);
    _bookmarked = next;
    final current = state;
    if (current is HadithReady) {
      emit(current.copyWith(bookmarked: next));
    }
    try {
      await _bookmarks?.save(_packId, next);
    } on Object catch (error, stackTrace) {
      appLog('hadith bookmark save failed',
          name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
      _bookmarked = previous;
      final latest = state;
      if (!isClosed && latest is HadithReady) {
        emit(latest.copyWith(bookmarked: previous));
      }
      return;
    }
    if (_bookmarksOnly) {
      await _load(0, bookmarksOnly: true);
    }
  }

  /// Loads the next page; a no-op when the last page was reached.
  Future<void> next() {
    final s = state;
    if (s is! HadithReady || !s.hasMore || s.bookmarksOnly) {
      return Future<void>.value();
    }
    return _load(s.offset + pageSize, query: s.query);
  }

  /// Loads the previous page; a no-op on the first page.
  Future<void> prev() {
    final s = state;
    if (s is! HadithReady || s.offset <= 0 || s.bookmarksOnly) {
      return Future<void>.value();
    }
    return _load(s.offset - pageSize, query: s.query);
  }

  Future<void> _load(
    int offset, {
    String? query,
    bool? bookmarksOnly,
    bool allowFallback = true,
  }) async {
    if (_paging) return;
    _paging = true;
    try {
      final q = query ?? _query;
      final only = bookmarksOnly ?? _bookmarksOnly;
      List<HadithItem> items = const <HadithItem>[];
      var hasMore = false;
      var packTitle = _packId;
      var language = '';
      var effectiveOffset = offset;
      try {
        final rows = await _downloader.installedPacks();
        final row = rows.where((r) => r.packId == _packId).firstOrNull;
        packTitle = row?.title ?? _packId;
        language = row?.language ?? '';
        if (only) {
          items = await _downloader.hadithByNumbers(_packId, _bookmarked);
          effectiveOffset = 0;
        } else if (q.isNotEmpty) {
          (items, hasMore) = await _downloader.hadithSearch(
            _packId,
            q,
            offset: offset,
            limit: pageSize,
          );
        } else {
          (items, hasMore) = await _downloader.hadithPage(
            _packId,
            offset,
            pageSize,
          );
        }
      } on Object catch (error, stackTrace) {
        appLog('hadith load failed',
            name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
        if (isClosed) return;
        emit(const HadithState.failed());
        return;
      }
      if (items.isEmpty && !only && q.isEmpty && offset > 0 && allowFallback) {
        // The saved offset is past the end (the pack changed): restart.
        _paging = false;
        await _load(0, query: q, bookmarksOnly: only, allowFallback: false);
        return;
      }
      _query = q;
      _bookmarksOnly = only;
      if (isClosed) return;
      emit(HadithState.ready(
        packTitle: packTitle,
        language: language,
        items: items,
        offset: effectiveOffset,
        hasMore: hasMore,
        query: q,
        bookmarksOnly: only,
        bookmarked: _bookmarked,
      ));
      if (!only && q.isEmpty) {
        try {
          await _positions?.save(_packId, effectiveOffset);
        } on Object catch (error, stackTrace) {
          appLog('hadith position save failed',
              name: 'quran_yahdi/hadith', error: error, stackTrace: stackTrace);
        }
      }
    } finally {
      _paging = false;
    }
  }
}
