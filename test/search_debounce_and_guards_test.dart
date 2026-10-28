import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_state.dart';

QuranSearchHit _hit(int id) => QuranSearchHit(
      ayahId: id,
      surahId: 1,
      numberInSurah: id,
      surahNameAr: 'الفاتحة',
      textImlaei: 'نص $id',
    );

QuranSearchPage _page(List<int> ids, {required bool hasMore}) =>
    QuranSearchPage(
      hits: [for (final id in ids) _hit(id)],
      total: ids.length,
      hasMore: hasMore,
    );

class _Fake implements QuranSearchSource {
  _Fake(this.onSearch);
  final Future<QuranSearchPage> Function(String q, int? after) onSearch;
  final queries = <String>[];

  @override
  Future<QuranSearchPage> search(String query,
      {int? afterAyahId, int limit = kQuranSearchPageSize}) {
    queries.add('$query|$afterAyahId');
    return onSearch(query, afterAyahId);
  }
}

void main() {
  test('rapid keystrokes collapse into one query', () async {
    final source = _Fake((q, _) async => _page([1], hasMore: false));
    final cubit =
        QuranSearchCubit(source, debounce: const Duration(milliseconds: 40));
    addTearDown(cubit.close);

    cubit.onQueryChanged('الص');
    cubit.onQueryChanged('الصلا');
    cubit.onQueryChanged('الصلاة');
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(source.queries, ['الصلاة|null']);
  });

  test('a failed next page is not retried by every scroll notification',
      () async {
    final source = _Fake((q, after) async {
      if (after == null) return _page([1, 2], hasMore: true);
      throw StateError('page failed');
    });
    final cubit = QuranSearchCubit(source, debounce: Duration.zero);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');
    await cubit.loadMore();
    await cubit.loadMore();
    await cubit.loadMore();

    final calls = source.queries.where((q) => q.endsWith('|2')).length;
    expect(calls, 1,
        reason: 'repeated scroll notifications must not reissue a failed page');
  });

  test('a failed page is reissued only by the explicit retry', () async {
    var nextPageCalls = 0;
    final source = _Fake((q, after) async {
      if (after == null) return _page([1, 2], hasMore: true);
      nextPageCalls++;
      if (nextPageCalls == 1) throw StateError('page failed');
      if (nextPageCalls == 2) return _page([3], hasMore: true);
      throw StateError('page failed again');
    });
    final cubit = QuranSearchCubit(source, debounce: Duration.zero);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');
    await cubit.loadMore();

    var state = cubit.state as QuranSearchReady;
    expect(state.moreFailed, isTrue);
    expect(source.queries, ['الصلاة|null', 'الصلاة|2']);

    await cubit.loadMore();
    await cubit.loadMore();
    expect(source.queries, ['الصلاة|null', 'الصلاة|2'],
        reason: 'scroll notifications must not reissue a failed page');

    await cubit.retryMore();
    state = cubit.state as QuranSearchReady;
    expect(state.moreFailed, isFalse);
    expect(source.queries, ['الصلاة|null', 'الصلاة|2', 'الصلاة|2'],
        reason: 'the retry reissues exactly one page at the same cursor');
    expect(state.hits.map((h) => h.ayahId), [1, 2, 3]);

    await cubit.loadMore();
    state = cubit.state as QuranSearchReady;
    expect(state.moreFailed, isTrue);

    await cubit.retryMore();
    state = cubit.state as QuranSearchReady;
    expect(state.moreFailed, isTrue,
        reason: 'a second failure keeps the retry affordance available');
    expect(source.queries,
        ['الصلاة|null', 'الصلاة|2', 'الصلاة|2', 'الصلاة|3', 'الصلاة|3']);
  });

  test('a page from the old query cannot merge into the new query', () async {
    final oldPage = Completer<QuranSearchPage>();
    final newPage = Completer<QuranSearchPage>();
    final source = _Fake((q, after) {
      if (q == 'قديم' && after == null) {
        return Future.value(_page([1, 2], hasMore: true));
      }
      if (q == 'قديم') return oldPage.future;
      return newPage.future;
    });
    final cubit = QuranSearchCubit(source, debounce: Duration.zero);
    addTearDown(cubit.close);

    await cubit.search('قديم');
    // The new query is in flight while the old Ready state stays on screen,
    // so loadMore captures the NEW generation with the OLD query.
    final fresh = cubit.search('جديد');
    final more = cubit.loadMore();
    expect(
      source.queries,
      ['قديم|null', 'جديد|null', 'قديم|2'],
      reason: 'the race must be entered: paging the old query under the new '
          'generation',
    );
    newPage.complete(_page([9], hasMore: false));
    await fresh;
    oldPage.complete(_page([3], hasMore: false));
    await more;

    final state = cubit.state as QuranSearchReady;
    expect(state.query, 'جديد');
    expect(state.hits.map((h) => h.ayahId), [9]);
  });
}
