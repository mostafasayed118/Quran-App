import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/feelings_repository.dart';
import '../domain/feeling.dart';
import 'feelings_state.dart';

/// Q44: the two verses of one feeling.
class FeelingVersesCubit extends Cubit<FeelingVersesState> {
  FeelingVersesCubit(this._repo, this._feeling)
    : super(const FeelingVersesState.loading());

  final FeelingsRepository _repo;
  final FeelingKey _feeling;

  Future<void> start() async {
    try {
      final verses = await _repo.forFeeling(_feeling);
      emit(FeelingVersesState.ready(feeling: _feeling, verses: verses));
    } on Object catch (error, stackTrace) {
      appLog(
        'feeling verses load failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const FeelingVersesState.failed());
    }
  }
}
