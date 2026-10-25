import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/ayah_repository.dart';
import '../../data/ayah_source.dart';
import '../../data/bookmark_pager.dart';
import '../../data/verse_mapping.dart';
import 'bookmarks_state.dart';

/// The bookmarks screen: the user's bookmarked ayahs, newest first.
///
/// With a [BookmarkPager] the list is keyset-paged: the first page stays live
/// and older pages are appended below it. Without one it keeps the original
/// live full-list stream.
class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._repo, {BookmarkPager? pager})
      : _pager = pager,
        super(const BookmarksState.loading()) {
    final pager = _pager;
    if (pager == null) {
      _sub = _repo.watchBookmarkEntries().listen(
            _onEntries,
            onError: _onError,
          );
    } else {
      _pageSub = pager.watchFirstPage().listen(
            _onPage,
            onError: _onError,
          );
    }
  }

  final AyahSource _repo;
  final BookmarkPager? _pager;
  StreamSubscription<List<BookmarkEntry>>? _sub;
  StreamSubscription<BookmarkPage>? _pageSub;

  /// Live first page (newest bookmarks).
  List<BookmarkEntry> _first = const [];
  bool _firstHasMore = false;

  /// Older pages appended by [loadMore].
  final List<BookmarkEntry> _older = [];
  bool _olderHasMore = false;

  /// Removes the bookmark of [ayahId]; a row that is already unbookmarked
  /// stays removed (the reader star keeps the toggle).
  Future<void> remove(int ayahId) async {
    await _repo.deleteBookmark(ayahId);
    if (isClosed) return;
    _first = [
      for (final entry in _first)
        if (entry.ayah.id != ayahId) entry
    ];
    _older.removeWhere((entry) => entry.ayah.id == ayahId);
    _emit();
  }

  /// Appends the next older page; a no-op while there is none.
  Future<void> loadMore() async {
    final pager = _pager;
    final current = state;
    if (pager == null ||
        current is! BookmarksReady ||
        !current.hasMore ||
        current.loadingMore ||
        current.lastBookmarkId <= 0) {
      return;
    }
    emit(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await pager.entriesBefore(current.lastBookmarkId);
      if (isClosed) return;
      final known = {
        for (final entry in _first) entry.bookmarkId,
        for (final entry in _older) entry.bookmarkId,
      };
      for (final entry in page.entries) {
        if (known.add(entry.bookmarkId)) _older.add(entry);
      }
      _olderHasMore = page.hasMore;
      _emit();
    } on Object catch (error, stackTrace) {
      dev.log('bookmark page failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      final latest = state;
      if (latest is! BookmarksReady) return;
      emit(latest.copyWith(loadingMore: false, moreFailed: true));
    }
  }

  void _emit() {
    if (isClosed) return;
    final firstIds = {for (final entry in _first) entry.ayah.id};
    final entries = [
      for (final entry in _first) entry.ayah.toVerse(),
      for (final entry in _older)
        if (!firstIds.contains(entry.ayah.id)) entry.ayah.toVerse(),
    ];
    final current = state;
    emit(BookmarksState.ready(
      entries: entries,
      lastBookmarkId: _cursor(),
      hasMore: _hasMore(),
      loadingMore: current is BookmarksReady && current.loadingMore,
      moreFailed: current is BookmarksReady && current.moreFailed,
    ));
  }

  int _cursor() {
    if (_older.isNotEmpty) return _older.last.bookmarkId;
    if (_first.isNotEmpty) return _first.last.bookmarkId;
    return 0;
  }

  bool _hasMore() => _older.isNotEmpty ? _olderHasMore : _firstHasMore;

  void _onEntries(List<BookmarkEntry> entries) {
    if (isClosed) return;
    emit(BookmarksState.ready(
      entries: entries.map((e) => e.ayah.toVerse()).toList(),
    ));
  }

  void _onPage(BookmarkPage page) {
    if (isClosed) return;
    _first = page.entries;
    _firstHasMore = page.hasMore;
    _emit();
  }

  void _onError(Object error, StackTrace stackTrace) {
    dev.log('bookmarks stream failed',
        name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
    if (isClosed) return;
    emit(const BookmarksState.failed());
  }

  /// Cancels the bookmark subscriptions before closing the cubit.
  @override
  Future<void> close() {
    _sub?.cancel();
    _pageSub?.cancel();
    return super.close();
  }
}
