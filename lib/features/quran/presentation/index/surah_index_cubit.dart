import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/surah_repository.dart';
import 'surah_index_state.dart';

class SurahIndexCubit extends Cubit<SurahIndexState> {
  SurahIndexCubit(this._repo) : super(const SurahIndexState.loading()) {
    _sub = _repo.watchAll().listen((surahs) {
      _latest = surahs;
      _emitFiltered();
    });
  }

  final SurahRepository _repo;
  List<Surah> _latest = [];
  String _query = '';
  StreamSubscription<List<Surah>>? _sub;

  void setQuery(String raw) {
    _query = raw.trim();
    _emitFiltered();
  }

  void _emitFiltered() {
    if (isClosed) return;
    emit(SurahIndexState.loaded(surahs: _filter(_latest), query: _query));
  }

  List<Surah> _filter(List<Surah> surahs) {
    if (_query.isEmpty) return surahs;
    final q = _query.toLowerCase();
    return surahs.where((s) {
      return s.nameAr.contains(_query) ||
          s.nameAr.toLowerCase().contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.id.toString() == _query;
    }).toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
