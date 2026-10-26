import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/asma_repository.dart';
import 'asma_state.dart';

/// The 99 names screen: the name list and the selected name.
class AsmaCubit extends Cubit<AsmaState> {
  /// Creates the cubit; the constructor is side-effect free and does no
  /// work — [start] performs the first load.
  AsmaCubit({required AsmaRepository repository})
      : _repository = repository,
        super(const AsmaState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => load();

  final AsmaRepository _repository;

  /// Loads the names and emits them; a failure emits the failed state.
  Future<void> load() async {
    try {
      final names = await _repository.names();
      if (isClosed) return;
      emit(AsmaState.ready(names: names));
    } on Object catch (error, stackTrace) {
      dev.log('asma load failed',
          name: 'quran_yahdi/asma', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const AsmaState.failed());
    }
  }

  /// Selects a name (null clears the selection) and keeps the loaded list.
  void select(AsmaName? name) {
    if (isClosed) return;
    if (state case AsmaReady(:final names)) {
      emit(AsmaState.ready(names: names, selected: name));
    }
  }
}
