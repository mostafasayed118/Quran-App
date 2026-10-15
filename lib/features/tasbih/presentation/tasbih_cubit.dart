import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/tasbih_repository.dart';
import 'tasbih_state.dart';

class TasbihCubit extends Cubit<TasbihState> {
  TasbihCubit({
    required TasbihRepository repo,
  })  : _repo = repo,
        super(const TasbihState.ready()) {
    unawaited(_hydrate());
  }

  static const List<int> targets = <int>[33, 99, 100, 500];

  final TasbihRepository _repo;
  final Completer<void> _loaded = Completer<void>();

  Future<void> get loaded => _loaded.future;

  Future<void> _hydrate() async {
    final snapshot = await _repo.load();
    if (isClosed) return;
    if (snapshot != null) {
      emit(TasbihState.ready(
        count: snapshot.count,
        target: snapshot.target,
      ));
    }
    _loaded.complete();
  }

  Future<void> increment() async {
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
    final snapshot = this.state as TasbihReady;
    await _repo.save(snapshot.count, snapshot.target);
  }

  Future<void> reset() async {
    final state = this.state;
    if (state is! TasbihReady) return;
    if (isClosed) return;
    emit(TasbihState.ready(count: 0, target: state.target));
    await _repo.save(0, state.target);
  }

  Future<void> selectTarget(int target) async {
    if (isClosed) return;
    emit(TasbihState.ready(target: target));
    await _repo.save(0, target);
  }
}
