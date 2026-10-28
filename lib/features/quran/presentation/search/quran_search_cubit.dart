import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/quran_search_source.dart';
import 'quran_search_state.dart';

/// Drives the Quran text search: one query, keyset-paged result pages.
class QuranSearchCubit extends Cubit<QuranSearchState> {
  QuranSearchCubit(
    this._source, {
    Duration debounce = Duration.zero,
  })  : _debounceDuration = debounce,
        super(const QuranSearchState.ready(
          query: '',
          hits: [],
          total: 0,
          hasMore: false,
        ));

  final QuranSearchSource _source;
  final Duration _debounceDuration;
  Timer? _debounce;

  /// UI entry point: coalesces typing bursts. [search] remains the immediate
  /// path used by tests and by a restored query.
  void onQueryChanged(String rawQuery) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(search(rawQuery));
    });
  }

  /// Bumped on every new query so an older, slower response cannot overwrite
  /// the results of the current one.
  int _generation = 0;

  /// Runs [rawQuery] from the start; short queries settle without a DB hit.
  Future<void> search(String rawQuery) async {
    final query = rawQuery.trim();
    final generation = ++_generation;
    if (!quranSearchQueryUsable(query)) {
      emit(QuranSearchState.ready(
        query: query,
        hits: const [],
        total: 0,
        hasMore: false,
      ));
      return;
    }
    // Keep the previous page on screen while typing: a Loading flash on every
    // keystroke reads as a broken field.
    if (state is! QuranSearchReady) emit(const QuranSearchState.loading());
    try {
      final page = await _source.search(query);
      if (isClosed || generation != _generation) return;
      emit(QuranSearchState.ready(
        query: query,
        hits: page.hits,
        total: page.total,
        hasMore: page.hasMore,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('quran search failed',
          name: 'quran_yahdi/search', error: error, stackTrace: stackTrace);
      if (isClosed || generation != _generation) return;
      emit(const QuranSearchState.failed());
    }
  }

  /// Appends the next page; a no-op unless the current page has more.
  Future<void> loadMore() async {
    final current = state;
    if (current is! QuranSearchReady ||
        !current.hasMore ||
        current.loadingMore ||
        current.moreFailed ||
        current.hits.isEmpty) {
      return;
    }
    final generation = _generation;
    final query = current.query;
    emit(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await _source.search(
        query,
        afterAyahId: current.hits.last.ayahId,
      );
      if (isClosed || generation != _generation) return;
      final latest = state;
      if (latest is! QuranSearchReady || latest.query != query) return;
      emit(latest.copyWith(
        hits: [...latest.hits, ...page.hits],
        total: page.total,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('quran search page failed',
          name: 'quran_yahdi/search', error: error, stackTrace: stackTrace);
      if (isClosed || generation != _generation) return;
      final latest = state;
      if (latest is! QuranSearchReady) return;
      emit(latest.copyWith(loadingMore: false, moreFailed: true));
    }
  }

  /// Reissues the failed next page; a no-op unless the last page failed.
  ///
  /// [loadMore] refuses while [QuranSearchReady.moreFailed] is set, so the
  /// caller clears the flag first and then runs the normal paging path.
  Future<void> retryMore() async {
    final current = state;
    if (current is! QuranSearchReady ||
        !current.moreFailed ||
        current.loadingMore) {
      return;
    }
    emit(current.copyWith(moreFailed: false));
    await loadMore();
  }

  /// Cancels a pending debounce before closing the cubit.
  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
