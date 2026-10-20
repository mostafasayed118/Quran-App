import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reciter_mapping.dart';
import '../../data/reciter_repository.dart';
import '../../data/reciter_source.dart';
import '../../domain/reciter_info.dart';
import 'reciters_state.dart';

/// The reciters screen: the reciter list and its search box.
class RecitersCubit extends Cubit<RecitersState> {
  /// Creates the cubit and subscribes to the reciter stream.
  ///
  /// The subscription is the source of truth; the first empty emission
  /// triggers a one-shot API refresh.
  RecitersCubit({required ReciterSource repo})
      : _repo = repo,
        super(const RecitersState.loading()) {
    _sub = _repo
        .watchAll()
        .map((rows) => [for (final row in sortReciters(rows)) row.toInfo()])
        .listen(
      (reciters) {
        _latest = reciters;
        _emitFiltered();
        _kickOnce();
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('reciters stream failed',
            name: 'quran_yahdi/reciters', error: error, stackTrace: stackTrace);
        if (isClosed) return;
        emit(const RecitersState.failed());
      },
    );
  }

  final ReciterSource _repo;
  List<ReciterInfo> _latest = [];
  String _query = '';
  bool _kicked = false;
  StreamSubscription<List<ReciterInfo>>? _sub;

  /// Filters the list by [raw] (trimmed); an empty query shows every reciter.
  void setQuery(String raw) {
    _query = raw.trim();
    _emitFiltered();
  }

  /// Soft network refresh; failures never kill the cached list. The raw
  /// exception is logged, never surfaced: the banner shows localized copy.
  Future<void> refresh() async {
    try {
      await _repo.refreshFromApi();
    } on Object catch (error, stackTrace) {
      dev.log('reciters refresh failed',
          name: 'quran_yahdi/reciters', error: error, stackTrace: stackTrace);
      _failSoft();
    }
  }

  void _kickOnce() {
    if (_kicked || _latest.isNotEmpty) return;
    _kicked = true;
    unawaited(refresh());
  }

  void _failSoft() {
    if (isClosed) return;
    final s = state;
    if (s is RecitersReady) {
      emit(s.copyWith(dataError: true));
    } else {
      emit(RecitersState.ready(
          reciters: const <ReciterInfo>[], query: _query, dataError: true));
    }
  }

  void _emitFiltered() {
    if (isClosed) return;
    emit(RecitersState.ready(
      reciters: _filter(_latest),
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

  List<ReciterInfo> _filter(List<ReciterInfo> reciters) {
    if (_query.isEmpty) return reciters;
    return reciters
        .where((r) =>
            r.reciterName.contains(_query) || r.moshafName.contains(_query))
        .toList();
  }

  /// Cancels the reciter subscription before closing the cubit.
  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
