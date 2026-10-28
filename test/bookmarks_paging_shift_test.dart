import 'dart:async';

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

BookmarkPage _page(List<int> ids, {required bool hasMore}) => BookmarkPage(
      entries: [
        for (final id in ids) _entry(bookmarkId: id, ayahId: id),
      ],
      hasMore: hasMore,
    );

/// The rendered ayah ids, in order.
List<int> _ids(BookmarksState state) =>
    (state as BookmarksReady).entries.map((verse) => verse.id).toList();

class _FakePager implements BookmarkPager {
  _FakePager({required this.firstPages, required this.onEntriesBefore});

  final Stream<BookmarkPage> firstPages;
  final Future<BookmarkPage> Function(int cursor) onEntriesBefore;
  final cursors = <int>[];

  @override
  Stream<BookmarkPage> watchFirstPage({int limit = kBookmarkPageSize}) =>
      firstPages;

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

/// A cubit fed by a controllable page-1 stream, so a test can re-emit page 1
/// the way the live pager does when a bookmark is added.
class _Harness {
  _Harness(this.onEntriesBefore) {
    pager = _FakePager(
      firstPages: firstPages.stream,
      onEntriesBefore: onEntriesBefore,
    );
    cubit = BookmarksCubit(_FakeAyahSource(), pager: pager);
  }

  final Future<BookmarkPage> Function(int cursor) onEntriesBefore;
  final firstPages = StreamController<BookmarkPage>();
  late final _FakePager pager;
  late final BookmarksCubit cubit;

  Future<void> start(BookmarkPage page1) async {
    await cubit.start();
    await emitPage1(page1);
  }

  /// Re-emits the live first page, as the pager does on every bookmark change.
  Future<void> emitPage1(BookmarkPage page) async {
    firstPages.add(page);
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    await cubit.close();
    await firstPages.close();
  }
}

void main() {
  test('a new bookmark that shifts page 1 keeps the row it pushed out',
      () async {
    final harness = _Harness(
      (_) async => _page(const [8, 7], hasMore: false),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    await harness.cubit.loadMore();
    expect(_ids(harness.cubit.state), [10, 9, 8, 7]);

    // A newer bookmark lands: page 1 becomes [11, 10] and 9 falls off its end.
    await harness.emitPage1(_page(const [11, 10], hasMore: true));

    expect(
      _ids(harness.cubit.state),
      [11, 10, 9, 8, 7],
      reason: 'the row pushed off page 1 must stay visible',
    );
    expect(
      (harness.cubit.state as BookmarksReady).lastBookmarkId,
      7,
      reason: 'the cursor stays on the last rendered row, never the new floor',
    );
  });

  test('a shifted page 1 renders every ayah exactly once', () async {
    final harness = _Harness(
      (_) async => _page(const [8, 7], hasMore: false),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    await harness.cubit.loadMore();

    await harness.emitPage1(_page(const [11, 10], hasMore: true));
    await harness.emitPage1(_page(const [11, 10], hasMore: true));

    final ids = _ids(harness.cubit.state);
    expect(ids, [11, 10, 9, 8, 7]);
    expect(ids.toSet(), hasLength(ids.length), reason: 'no duplicate rows');
  });

  test('a delete that pulls an older row up never revives the deleted row',
      () async {
    final harness = _Harness(
      (_) async => _page(const [8, 7], hasMore: false),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    await harness.cubit.loadMore();

    // Ayah 9 is unbookmarked and row 8 moves up into the first page.
    await harness.emitPage1(_page(const [10, 8], hasMore: true));

    expect(_ids(harness.cubit.state), [10, 8, 7]);
    expect(
      _ids(harness.cubit.state),
      isNot(contains(9)),
      reason: 'a row pulled up into page 1 must not be carried back',
    );
  });

  test('a landed page clears loadingMore and lets the next page load',
      () async {
    final harness = _Harness(
      (cursor) async => cursor == 9
          ? _page(const [8, 7], hasMore: true)
          : _page(const [6], hasMore: false),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    await harness.cubit.loadMore();

    expect(
      (harness.cubit.state as BookmarksReady).loadingMore,
      isFalse,
      reason: 'the footer spinner must stop once the page lands',
    );

    await harness.cubit.loadMore();
    expect(harness.pager.cursors, [9, 7],
        reason: 'a later scroll must reach the pager again');
    expect(_ids(harness.cubit.state), [10, 9, 8, 7, 6]);
  });

  test('a live page arriving mid-fetch keeps the in-flight spinner', () async {
    final release = Completer<BookmarkPage>();
    final harness = _Harness((_) => release.future);
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    final loading = harness.cubit.loadMore();
    await pumpEventQueue();
    expect((harness.cubit.state as BookmarksReady).loadingMore, isTrue);

    await harness.emitPage1(_page(const [11, 10], hasMore: true));
    expect(
      (harness.cubit.state as BookmarksReady).loadingMore,
      isTrue,
      reason: 'the fetch is still in flight, so the spinner stays up',
    );

    release.complete(_page(const [8, 7], hasMore: false));
    await loading;
    expect((harness.cubit.state as BookmarksReady).loadingMore, isFalse);
    expect(_ids(harness.cubit.state), [11, 10, 9, 8, 7]);
  });

  test('a plain loadMore still appends older rows in order', () async {
    final harness = _Harness(
      (_) async => _page(const [8, 7], hasMore: true),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));

    await harness.cubit.loadMore();
    expect(_ids(harness.cubit.state), [10, 9, 8, 7]);
    expect(harness.pager.cursors, [9]);
    expect((harness.cubit.state as BookmarksReady).hasMore, isTrue);
  });

  test('after a shift the cursor asks for rows strictly below the last id',
      () async {
    final harness = _Harness(
      (_) async => _page(const [8, 7], hasMore: false),
    );
    addTearDown(harness.dispose);

    await harness.start(_page(const [10, 9], hasMore: true));
    await harness.emitPage1(_page(const [11, 10], hasMore: true));

    final shifted = harness.cubit.state as BookmarksReady;
    expect(shifted.hasMore, isTrue,
        reason: 'rows below the carried row are still unread');
    expect(shifted.lastBookmarkId, 9);

    await harness.cubit.loadMore();
    expect(harness.pager.cursors, [9],
        reason: 'the next page starts below the last rendered id');
    expect(_ids(harness.cubit.state), [11, 10, 9, 8, 7]);
  });
}
