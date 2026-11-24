import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/feelings_repository.dart';
import '../domain/feeling.dart';
import '../domain/saved_feeling_verse.dart';

part 'feelings_state.freezed.dart';

@freezed
sealed class FeelingsState with _$FeelingsState {
  const factory FeelingsState.loading() = FeelingsLoading;
  const factory FeelingsState.failed() = FeelingsFailed;
  const factory FeelingsState.ready({
    required List<Feeling> feelings,
    required String heroExcerpt,
    required int savedCount,
  }) = FeelingsReady;
}

@freezed
sealed class FeelingVersesState with _$FeelingVersesState {
  const factory FeelingVersesState.loading() = FeelingVersesLoading;
  const factory FeelingVersesState.failed() = FeelingVersesFailed;
  const factory FeelingVersesState.ready({
    required FeelingKey feeling,
    required List<FeelingVerseView> verses,
  }) = FeelingVersesReady;
}

@freezed
sealed class VerseDetailState with _$VerseDetailState {
  const factory VerseDetailState.loading() = VerseDetailLoading;
  const factory VerseDetailState.failed() = VerseDetailFailed;
  const factory VerseDetailState.ready({
    required FeelingVerseView verse,
    required bool isSaved,
  }) = VerseDetailReady;
}

@freezed
sealed class SavedVersesState with _$SavedVersesState {
  const factory SavedVersesState.loading() = SavedVersesLoading;
  const factory SavedVersesState.ready({
    required List<SavedFeelingVerse> verses,
  }) = SavedVersesReady;
}
