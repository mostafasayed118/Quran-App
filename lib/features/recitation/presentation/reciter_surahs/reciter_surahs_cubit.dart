import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reciter_mapping.dart';
import '../../data/reciter_repository.dart';
import '../../data/reciter_source.dart';
import '../downloads/downloads_cubit.dart';
import 'reciter_surahs_state.dart';

/// The surahs of one reciter: the available list, the names and the teasers.
class ReciterSurahsCubit extends Cubit<ReciterSurahsState> {
  /// Creates the cubit for one reciter row and starts the load.
  ///
  /// The load is fire-and-forget: the state moves from loading to
  /// ready/failed on its own.
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

  /// Loads the reciter's surah list, names and ayah teasers.
  ///
  /// An unknown reciter row fails the screen (the state is failed, never a
  /// raw exception). The download state is refreshed before the emission so
  /// the per-surah download badges are already correct.
  Future<void> load() async {
    try {
      final row = await _reciters.byId(_rowId);
      if (isClosed) return;
      if (row == null) {
        dev.log('reciter row not found',
            name: 'quran_yahdi/reciter_surahs', error: _rowId);
        emit(const ReciterSurahsState.failed());
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
    } on Object catch (error, stackTrace) {
      dev.log('reciter surahs load failed',
          name: 'quran_yahdi/reciter_surahs',
          error: error,
          stackTrace: stackTrace);
      if (!isClosed) emit(const ReciterSurahsState.failed());
    }
  }

  /// Makes this reciter the default one (the moshaf selection).
  Future<void> setAsDefault() async {
    await _reciters.selectMoshaf(_rowId);
  }
}
