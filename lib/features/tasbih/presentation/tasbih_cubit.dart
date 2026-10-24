import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/tasbih_repository.dart';
import 'tasbih_state.dart';

/// The tasbih screen: the counter, its target and the persisted snapshot.
class TasbihCubit extends Cubit<TasbihState> {
  /// Creates the cubit and hydrates it from the stored snapshot.
  ///
  /// The hydration is fire-and-forget; await [loaded] to wait for it.
  TasbihCubit({
    required TasbihRepository repo,
  })  : _repo = repo,
        super(const TasbihState.ready()) {
    unawaited(_hydrate());
  }

  /// The counter targets the user can pick (33, 99, 100 and 500).
  static const List<int> targets = <int>[33, 99, 100, 500];

  final TasbihRepository _repo;
  final Completer<void> _loaded = Completer<void>();

  /// True once the user changed the counter; hydration must not overwrite it.
  bool _userMutated = false;

  /// Completes when the stored snapshot has been applied (or failed).
  Future<void> get loaded => _loaded.future;

  Future<void> _hydrate() async {
    try {
      final snapshot = await _repo.load();
      if (isClosed) return;
      if (snapshot != null && !_userMutated) {
        emit(TasbihState.ready(
          count: snapshot.count,
          target: snapshot.target,
        ));
      }
    } on Object catch (error, stackTrace) {
      dev.log('tasbih load failed',
          name: 'quran_yahdi/tasbih', error: error, stackTrace: stackTrace);
    } finally {
      if (!_loaded.isCompleted) {
        _loaded.complete();
      }
    }
  }

  /// Counts one tap and persists the new count.
  ///
  /// [TasbihState.reachedTarget] flips exactly on the target count, not
  /// beyond it.
  Future<void> increment() async {
    _userMutated = true;
    final state = this.state;
    if (state is! TasbihReady) return;
    final next = state.count + 1;
    final reached = next == state.target;
    if (isClosed) return;
    emit(TasbihState.ready(
      count: next,
      target: state.target,
      reachedTarget: reached,
    ));
    await _save(next, state.target);
  }

  /// Resets the counter to zero (the target is kept) and persists it.
  Future<void> reset() async {
    _userMutated = true;
    final state = this.state;
    if (state is! TasbihReady) return;
    if (isClosed) return;
    emit(TasbihState.ready(count: 0, target: state.target));
    await _save(0, state.target);
  }

  /// Picks the counter target and resets the count to zero.
  Future<void> selectTarget(int target) async {
    _userMutated = true;
    if (isClosed) return;
    emit(TasbihState.ready(target: target));
    await _save(0, target);
  }

  Future<void> _save(int count, int target) async {
    try {
      await _repo.save(count, target);
    } on Object catch (error, stackTrace) {
      dev.log('tasbih save failed',
          name: 'quran_yahdi/tasbih', error: error, stackTrace: stackTrace);
    }
  }
}
