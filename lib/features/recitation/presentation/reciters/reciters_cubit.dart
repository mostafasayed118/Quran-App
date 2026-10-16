import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/reciter_repository.dart';
import 'reciters_state.dart';

class RecitersCubit extends Cubit<RecitersState> {
  RecitersCubit({required ReciterRepository repo})
      : _repo = repo,
        super(const RecitersState.loading()) {
    _sub = _repo.watchAll().listen(
      (rows) {
        _latest = rows;
        _emitFiltered();
        _kickOnce();
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(RecitersState.error(message: error.toString()));
      },
    );
  }

  final ReciterRepository _repo;
  List<ReciterRow> _latest = [];
  String _query = '';
  bool _kicked = false;
  StreamSubscription<List<ReciterRow>>? _sub;

  void setQuery(String raw) {
    _query = raw.trim();
    _emitFiltered();
  }

  /// Soft network refresh; failures never kill the cached list.
  Future<void> refresh() async {
    try {
      await _repo.refreshFromApi();
    } on Object catch (e) {
      _failSoft('$e');
    }
  }

  void _kickOnce() {
    if (_kicked || _latest.isNotEmpty) return;
    _kicked = true;
    unawaited(refresh());
  }

  void _failSoft(String message) {
    if (isClosed) return;
    final s = state;
    if (s is RecitersReady) {
      emit(s.copyWith(dataError: message));
    } else {
      emit(RecitersState.ready(
          reciters: const <ReciterRow>[], query: _query, dataError: message));
    }
  }

  void _emitFiltered() {
    if (isClosed) return;
    emit(RecitersState.ready(
      reciters: sortReciters(_filter(_latest)),
      query: _query,
    ));
  }

  /// Dismisses the soft network failure banner until the next failure.
  void clearDataError() {
    if (isClosed) return;
    final s = state;
    if (s is! RecitersReady) return;
    emit(RecitersState.ready(reciters: s.reciters, query: s.query));
  }

  List<ReciterRow> _filter(List<ReciterRow> rows) {
    if (_query.isEmpty) return rows;
    return rows
        .where((r) =>
            r.reciterName.contains(_query) || r.moshafName.contains(_query))
        .toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
