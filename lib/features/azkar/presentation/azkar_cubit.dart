import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/azkar_repository.dart';
import 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit({required AzkarRepository repository})
      : _repository = repository,
        super(const AzkarState.loading()) {
    unawaited(load());
  }

  final AzkarRepository _repository;

  List<AzkarCollection> _collections = const [];
  int _searchSeq = 0;

  Future<void> load() async {
    try {
      final collections = await _repository.collections();
      if (isClosed) return;
      _collections = collections;
      _searchSeq++;
      emit(AzkarState.browsing(collections: collections));
    } on Object catch (error, stackTrace) {
      dev.log('azkar load failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const AzkarState.failed());
    }
  }

  /// Empty (or whitespace-only) queries restore the plain collection list.
  void setSearchQuery(String raw) {
    if (isClosed) return;
    final query = raw.trim();
    final seq = ++_searchSeq;
    if (query.isEmpty) {
      emit(AzkarState.browsing(collections: _collections));
      return;
    }
    unawaited(_search(query, seq));
  }

  Future<void> _search(String query, int seq) async {
    try {
      final results = await _repository.search(query);
      if (isClosed || seq != _searchSeq) return;
      emit(AzkarState.browsing(
        collections: _collections,
        query: query,
        searchResults: results.hits,
        searchHasMore: results.hasMore,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('azkar search failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _searchSeq) return;
      emit(AzkarState.browsing(collections: _collections));
    }
  }

  void open(AzkarCollection collection) {
    if (isClosed) return;
    _searchSeq++;
    emit(AzkarState.reciting(
      collection: collection,
      remaining: [
        for (final item in collection.items) item.count,
      ],
    ));
  }

  void tapItem(int index) {
    if (isClosed) return;
    final state = this.state;
    if (state is! AzkarReciting) return;
    if (index < 0 || index >= state.remaining.length) return;
    final item = state.collection.items[index];
    final next = (state.remaining[index] - 1).clamp(0, item.count);
    final remaining = [...state.remaining]..[index] = next;
    emit(AzkarState.reciting(
      collection: state.collection,
      remaining: remaining,
    ));
  }

  void back() {
    if (isClosed) return;
    unawaited(load());
  }
}
