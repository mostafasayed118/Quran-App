import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/arabic_search.dart';
import '../../data/surah_source.dart';
import '../../domain/surah_summary.dart';
import 'surah_index_state.dart';

/// The surah index screen: the surah list and its search box.
class SurahIndexCubit extends Cubit<SurahIndexState> {
  /// Creates the cubit and subscribes to the surah stream.
  ///
  /// The subscription is the source of truth: every change re-emits the
  /// ready state (re-filtered by the current query).
  SurahIndexCubit(this._repo) : super(const SurahIndexState.loading()) {
    _sub = _repo.watchSummaries().listen(
      (surahs) {
        _latest = surahs;
        _emitFiltered();
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('surah index stream failed',
            name: 'quran_yahdi/surah_index',
            error: error,
            stackTrace: stackTrace);
        if (isClosed) return;
        emit(const SurahIndexState.failed());
      },
    );
  }

  final SurahSource _repo;
  List<SurahSummary> _latest = [];
  String _query = '';
  StreamSubscription<List<SurahSummary>>? _sub;

  /// Filters the list by [raw] (trimmed); an empty query shows every surah.
  void setQuery(String raw) {
    _query = raw.trim();
    _emitFiltered();
  }

  void _emitFiltered() {
    if (isClosed) return;
    emit(SurahIndexState.ready(
      surahs: _filter(_latest),
      query: _query,
    ));
  }

  List<SurahSummary> _filter(List<SurahSummary> surahs) {
    if (_query.isEmpty) return surahs;
    final westernQuery = _query.toWesternDigits;
    return surahs.where((s) {
      return matchesQuery(s.nameAr, _query) ||
          matchesQuery(s.nameEn, _query) ||
          s.id.toString() == westernQuery;
    }).toList();
  }

  /// Cancels the surah subscription before closing the cubit.
  @override
  Future<void> close() async {
    try {
      await _sub?.cancel();
    } finally {
      await super.close();
    }
  }
}
