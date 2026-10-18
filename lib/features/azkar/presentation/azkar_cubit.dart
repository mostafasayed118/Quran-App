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

  Future<void> load() async {
    try {
      final collections = await _repository.collections();
      if (isClosed) return;
      emit(AzkarState.browsing(collections: collections));
    } on Object catch (error, stackTrace) {
      dev.log('azkar load failed',
          name: 'quran_yahdi/azkar', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const AzkarState.failed());
    }
  }

  void open(AzkarCollection collection) {
    if (isClosed) return;
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
