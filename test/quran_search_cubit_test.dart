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

QuranSearchPage _page(List<int> ids,
        {required int total, required bool hasMore}) =>
    QuranSearchPage(
      hits: [for (final id in ids) _hit(id)],
      total: total,
      hasMore: hasMore,
    );

class _FakeSource implements QuranSearchSource {
  _FakeSource(this.onSearch);

  final Future<QuranSearchPage> Function(String query, int? afterAyahId)
      onSearch;
  final List<String> queries = [];

  @override
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  }) {
    queries.add(query);
    return onSearch(query, afterAyahId);
  }
}

void main() {
  test('search emits the first page', () async {
    final source = _FakeSource(
      (_, __) async => _page([1, 2, 3], total: 3, hasMore: false),
    );
    final cubit = QuranSearchCubit(source);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');

    final state = cubit.state as QuranSearchReady;
    expect(state.hits.map((h) => h.ayahId), [1, 2, 3]);
    expect(state.total, 3);
    expect(state.hasMore, false);
  });

  test('short query settles without hitting the source', () async {
    final source = _FakeSource(
      (_, __) async => _page([1], total: 1, hasMore: false),
    );
    final cubit = QuranSearchCubit(source);
    addTearDown(cubit.close);

    await cubit.search('ا');

    final state = cubit.state as QuranSearchReady;
    expect(state.hits, isEmpty);
    expect(source.queries, isEmpty);
  });

  test('loadMore appends pages and stops at the end', () async {
    final source = _FakeSource(
      (_, afterAyahId) async => afterAyahId == null
          ? _page([1, 2], total: 3, hasMore: true)
          : _page([3], total: 3, hasMore: false),
    );
    final cubit = QuranSearchCubit(source);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');
    await cubit.loadMore();

    var state = cubit.state as QuranSearchReady;
    expect(state.hits.map((h) => h.ayahId), [1, 2, 3]);
    expect(state.hasMore, false);

    await cubit.loadMore();
    state = cubit.state as QuranSearchReady;
    expect(source.queries, hasLength(2));
    expect(state.hits, hasLength(3));
  });

  test('a stale response cannot overwrite a newer query', () async {
    final stale = Completer<QuranSearchPage>();
    final fresh = Completer<QuranSearchPage>();
    final source = _FakeSource((query, __) {
      return query == 'قديم' ? stale.future : fresh.future;
    });
    final cubit = QuranSearchCubit(source);
    addTearDown(cubit.close);

    final first = cubit.search('قديم');
    final second = cubit.search('جديد');
    fresh.complete(_page([2], total: 1, hasMore: false));
    await second;
    stale.complete(_page([1], total: 1, hasMore: false));
    await first;

    final state = cubit.state as QuranSearchReady;
    expect(state.query, 'جديد');
    expect(state.hits.single.ayahId, 2);
  });

  test('failure emits the failed state', () async {
    final source = _FakeSource((_, __) async => throw StateError('boom'));
    final cubit = QuranSearchCubit(source);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');

    expect(cubit.state, isA<QuranSearchFailed>());
  });
}
