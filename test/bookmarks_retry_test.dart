import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_pager.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_state.dart';

BookmarkEntry _entry({required int bookmarkId, required int ayahId}) =>
    BookmarkEntry(
      bookmarkId: bookmarkId,
      ayah: Ayah(
        id: ayahId,
        surahId: 1,
        numberInSurah: ayahId,
        juz: 1,
        page: 1,
        textUthmani: 'نص $ayahId',
        textImlaei: 'نص $ayahId',
        sajda: false,
      ),
    );

class _FakePager implements BookmarkPager {
  _FakePager({required this.firstPage, required this.onEntriesBefore});

  final BookmarkPage firstPage;
  final Future<BookmarkPage> Function(int cursor) onEntriesBefore;
  final cursors = <int>[];

  @override
  Stream<BookmarkPage> watchFirstPage({int limit = kBookmarkPageSize}) =>
      Stream<BookmarkPage>.value(firstPage);

  @override
  Future<BookmarkPage> entriesBefore(
    int beforeBookmarkId, {
    int limit = kBookmarkPageSize,
  }) {
    cursors.add(beforeBookmarkId);
    return onEntriesBefore(beforeBookmarkId);
  }
}

class _FakeAyahSource implements AyahSource {
  @override
  Future<Ayah?> ayahById(int ayahId) async => null;

  @override
  Future<List<Ayah>> ayahsForRange(
          int surahId, int fromAyah, int toAyah) async =>
      const [];

  @override
  Future<void> deleteBookmark(int ayahId) async {}

  @override
  Future<Surah?> surahById(int surahId) async => null;

  @override
  Future<List<Ayah>> surahAyahs(int surahId) async => const [];

  @override
  Future<void> toggleBookmark(int ayahId) async {}

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() =>
      const Stream<List<BookmarkEntry>>.empty();

  @override
  Stream<Set<int>> watchBookmarkedIds() => const Stream<Set<int>>.empty();
}

void main() {
  test('retryMore recovers a failed bookmark page exactly once', () async {
    var failuresLeft = 1;
    final pager = _FakePager(
      firstPage: BookmarkPage(
        entries: [
          _entry(bookmarkId: 3, ayahId: 3),
          _entry(bookmarkId: 2, ayahId: 2),
        ],
        hasMore: true,
      ),
      onEntriesBefore: (cursor) async {
        if (failuresLeft > 0) {
          failuresLeft--;
          throw StateError('page failed');
        }
        return BookmarkPage(
          entries: [_entry(bookmarkId: 1, ayahId: 1)],
          hasMore: false,
        );
      },
    );
    final cubit = BookmarksCubit(_FakeAyahSource(), pager: pager);
    addTearDown(cubit.close);

    await cubit.start();
    await pumpEventQueue();

    var state = cubit.state as BookmarksReady;
    expect(state.hasMore, isTrue);
    expect(state.lastBookmarkId, 2);

    await cubit.loadMore();
    state = cubit.state as BookmarksReady;
    expect(state.moreFailed, isTrue);
    expect(pager.cursors, [2]);

    await cubit.loadMore();
    await cubit.loadMore();
    expect(pager.cursors, [2],
        reason: 'scroll notifications must not reissue a failed page');

    await cubit.retryMore();
    state = cubit.state as BookmarksReady;
    expect(pager.cursors, [2, 2],
        reason: 'the retry reissues exactly one page at the same cursor');
    expect(state.moreFailed, isFalse);
    expect(state.entries.map((verse) => verse.id), [3, 2, 1]);
  });
}
