import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/surah_summary.dart';

part 'surah_index_state.freezed.dart';

@freezed
sealed class SurahIndexState with _$SurahIndexState {
  const factory SurahIndexState.loading() = SurahIndexLoading;

  const factory SurahIndexState.loaded({
    @Default(<SurahSummary>[]) List<SurahSummary> surahs,
    @Default('') String query,
  }) = SurahIndexLoaded;

  const factory SurahIndexState.error({required String message}) =
      SurahIndexError;
}
