import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/asma_repository.dart';
import 'asma_state.dart';

class AsmaCubit extends Cubit<AsmaState> {
  AsmaCubit({required AsmaRepository repository})
      : _repository = repository,
        super(const AsmaState.loading()) {
    unawaited(load());
  }

  final AsmaRepository _repository;

  Future<void> load() async {
    final names = await _repository.names();
    if (isClosed) return;
    emit(AsmaState.ready(names: names));
  }

  void select(AsmaName? name) {
    if (isClosed) return;
    emit(AsmaState.ready(names: (state as AsmaReady).names, selected: name));
  }
}
