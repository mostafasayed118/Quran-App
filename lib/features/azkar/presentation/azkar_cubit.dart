import 'dart:async';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/azkar_repository.dart';
import '../data/azkar_saved_state.dart';
import 'azkar_state.dart';

/// The azkar screen: the collection list, the search results and the
/// reciting view (one counter per item).
class AzkarCubit extends Cubit<AzkarState> {
  /// Creates the cubit; the constructor is side-effect free and does no
  /// work — [start] performs the first load.
  ///
  /// [savedState] is optional: without it the counters live in memory for the
  /// session (the v1.0 behaviour), so a storage failure never blocks reciting.
  /// [clock] is the day seam for the once-a-day counter reset.
  AzkarCubit({
    required AzkarRepository repository,
    AzkarSavedStateSource? savedState,
    DateTime Function()? clock,
  })  : _repository = repository,
        _savedState = savedState,
        _clock = clock ?? DateTime.now,
        super(const AzkarState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => load();

  final AzkarRepository _repository;
  final AzkarSavedStateSource? _savedState;
  final DateTime Function() _clock;

  List<AzkarCollection> _catalog = const [];
  int _searchSeq = 0;
  AzkarSavedState _saved = const AzkarSavedState();

  /// Whether the stored state was merged already.
  ///
  /// The read happens once per cubit: after that [_saved] is the source of
  /// truth, so a reload cannot resurrect a counter that a tap already
  /// decremented while its write was still in flight.
  bool _hydrated = false;

  /// Loads the collections, emits the browsing state, then hydrates the saved
  /// counters and favorites.
  ///
  /// The catalog emit comes first on purpose: the screen must not wait for a
  /// storage read to paint (the same rule the boot path follows for plugins).
  /// A failure emits the failed state (the error is logged, never raised as
  /// an unhandled async error).
  Future<void> load() async {
    try {
      final collections = await _repository.collections();
      if (isClosed) return;
      _catalog = collections;
      _searchSeq++;
      emit(_browsing());
    } on Object catch (error, stackTrace) {
      appLog('azkar load failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const AzkarState.failed());
      return;
    }
    if (!_hydrated) await _hydrateSavedState();
  }

  /// Merges the stored counters and pins into the browsing state, once.
  ///
  /// Counters from an earlier day are dropped: morning and evening azkar are
  /// recited daily, so yesterday's finished session must not open at zeros.
  Future<void> _hydrateSavedState() async {
    final saved = await _readSavedState();
    if (isClosed) return;
    _hydrated = true;
    _saved = saved.day == _today
        ? saved
        : AzkarSavedState(favorites: saved.favorites);
    final state = this.state;
    if (state is AzkarBrowsing) {
      emit(state.copyWith(
        collections: _favoritesFirst(_catalog),
        favorites: _saved.favorites,
      ));
    }
  }

  /// Empty (or whitespace-only) queries restore the plain collection list.
  void setSearchQuery(String raw) {
    if (isClosed) return;
    final query = raw.trim();
    final seq = ++_searchSeq;
    if (query.isEmpty) {
      emit(_browsing());
      return;
    }
    unawaited(_search(query, seq));
  }

  Future<void> _search(String query, int seq) async {
    try {
      final results = await _repository.search(query);
      if (isClosed || seq != _searchSeq) return;
      emit(_browsing(
        query: query,
        searchResults: results.hits,
        searchHasMore: results.hasMore,
      ));
    } on Object catch (error, stackTrace) {
      appLog('azkar search failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _searchSeq) return;
      emit(_browsing(query: query));
    }
  }

  /// Opens a collection in the reciting view, resuming the saved counters
  /// when there are any (every item starts full otherwise).
  ///
  /// The tiles are tappable while the stored state is still being read, so an
  /// open that arrives before hydration waits for it: starting from the empty
  /// cache would show full counters and then persist those over saved
  /// progress. Once hydrated the open is synchronous.
  void open(AzkarCollection collection) {
    if (isClosed) return;
    if (_hydrated) {
      _emitReciting(collection);
      return;
    }
    unawaited(_hydrateThenOpen(collection));
  }

  Future<void> _hydrateThenOpen(AzkarCollection collection) async {
    await _hydrateSavedState();
    if (isClosed) return;
    _emitReciting(collection);
  }

  void _emitReciting(AzkarCollection collection) {
    _searchSeq++;
    emit(AzkarState.reciting(
      collection: collection,
      remaining: _remainingFor(collection),
    ));
  }

  /// Counts one tap on the item at [index]; the counter stops at zero.
  void tapItem(int index) {
    if (isClosed) return;
    final state = this.state;
    if (state is! AzkarReciting) return;
    if (index < 0 || index >= state.remaining.length) return;
    final item = state.collection.items[index];
    final next = (state.remaining[index] - 1).clamp(0, item.count);
    final remaining = [...state.remaining]..[index] = next;
    emit(state.copyWith(remaining: remaining));
    unawaited(_persistRemaining(state.collection.id, remaining));
  }

  /// Resets every counter of the open collection back to its full count.
  void restart() {
    if (isClosed) return;
    final state = this.state;
    if (state is! AzkarReciting) return;
    final remaining = [
      for (final item in state.collection.items) item.count,
    ];
    emit(state.copyWith(remaining: remaining));
    unawaited(_persistRemaining(state.collection.id, remaining));
  }

  /// Pins or unpins [collectionId]; pinned collections sort first.
  void toggleFavorite(String collectionId) {
    if (isClosed) return;
    final favorites = <String>{..._saved.favorites};
    if (!favorites.remove(collectionId)) favorites.add(collectionId);
    _saved = AzkarSavedState(
      day: _saved.day,
      remaining: _saved.remaining,
      favorites: favorites,
    );
    final state = this.state;
    if (state is AzkarBrowsing) {
      emit(state.copyWith(
        collections: _favoritesFirst(_catalog),
        favorites: favorites,
      ));
    }
    unawaited(_persistFavorites(favorites));
  }

  /// Leaves the reciting view and returns to the collection list.
  void back() {
    if (isClosed) return;
    unawaited(load());
  }

  AzkarState _browsing({
    String query = '',
    List<AzkarSearchHit> searchResults = const [],
    bool searchHasMore = false,
  }) {
    return AzkarState.browsing(
      collections: _favoritesFirst(_catalog),
      favorites: _saved.favorites,
      query: query,
      searchResults: searchResults,
      searchHasMore: searchHasMore,
    );
  }

  List<int> _remainingFor(AzkarCollection collection) {
    final saved = _liveRemaining[collection.id];
    return [
      for (var i = 0; i < collection.items.length; i++)
        if (saved != null && i < saved.length)
          saved[i].clamp(0, collection.items[i].count)
        else
          collection.items[i].count,
    ];
  }

  /// The counters that still belong to today.
  ///
  /// Morning and evening azkar are recited daily, so a set stamped with an
  /// earlier day is dropped — even while the screen stays open past midnight.
  /// An unstamped set (no storage source) is kept: it only lives in memory.
  Map<String, List<int>> get _liveRemaining {
    if (_saved.day.isEmpty || _saved.day == _today) return _saved.remaining;
    return const <String, List<int>>{};
  }

  List<AzkarCollection> _favoritesFirst(List<AzkarCollection> collections) {
    final favorites = _saved.favorites;
    if (favorites.isEmpty) return collections;
    return [
      for (final collection in collections)
        if (favorites.contains(collection.id)) collection,
      for (final collection in collections)
        if (!favorites.contains(collection.id)) collection,
    ];
  }

  Future<AzkarSavedState> _readSavedState() async {
    final source = _savedState;
    if (source == null) return const AzkarSavedState();
    try {
      return await source.load();
    } on Object catch (error, stackTrace) {
      appLog('azkar saved state read failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      return const AzkarSavedState();
    }
  }

  /// The local day stamp written with the counters.
  String get _today {
    final now = _clock();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _persistRemaining(
      String collectionId, List<int> remaining) async {
    final source = _savedState;
    if (source == null) return;
    final day = _today;
    // A screen left open past midnight must not relabel yesterday's counters
    // as today's: the whole set restarts with this write.
    _saved = AzkarSavedState(
      day: day,
      remaining: {
        ..._liveRemaining,
        collectionId: List<int>.unmodifiable(remaining),
      },
      favorites: _saved.favorites,
    );
    try {
      await source.saveRemaining(collectionId, remaining, day);
    } on Object catch (error, stackTrace) {
      appLog('azkar counter write failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _persistFavorites(Set<String> favorites) async {
    final source = _savedState;
    if (source == null) return;
    try {
      await source.saveFavorites(favorites);
    } on Object catch (error, stackTrace) {
      appLog('azkar favorites write failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
    }
  }
}
