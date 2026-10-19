import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reciter_mapping.dart';
import '../../data/reciter_repository.dart';
import '../../data/reciter_source.dart';
import '../downloads/downloads_cubit.dart';
import 'reciter_surahs_state.dart';

class ReciterSurahsCubit extends Cubit<ReciterSurahsState> {
  ReciterSurahsCubit({
    required ReciterSource reciters,
    required DownloadsCubit downloads,
    required String rowId,
  })  : _reciters = reciters,
        _downloads = downloads,
        _rowId = rowId,
        super(const ReciterSurahsState.loading()) {
    unawaited(load());
  }

  final ReciterSource _reciters;
  final DownloadsCubit _downloads;
  final String _rowId;

  Future<void> load() async {
    try {
      final row = await _reciters.byId(_rowId);
      if (isClosed) return;
      if (row == null) {
        emit(const ReciterSurahsState.error(message: 'reciter row not found'));
        return;
      }
      final surahs = parseSurahList(row.surahList);
      final names = await _reciters.surahNamesFor(surahs);
      final previews = await _reciters.ayahTeasersFor(surahs);
      if (isClosed) return;
      await _downloads.refreshDone();
      if (isClosed) return;
      emit(ReciterSurahsState.ready(
        row: row.toInfo(),
        surahNumbers: surahs,
        names: names,
        previews: previews,
      ));
    } on Object catch (e) {
      if (!isClosed) emit(ReciterSurahsState.error(message: '$e'));
    }
  }

  Future<void> setAsDefault() async {
    await _reciters.selectMoshaf(_rowId);
  }
}
