import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/db/app_database.dart';

part 'surah_index_state.freezed.dart';

@freezed
sealed class SurahIndexState with _$SurahIndexState {
  const factory SurahIndexState.loading() = SurahIndexLoading;

  const factory SurahIndexState.loaded({
    @Default(<Surah>[]) List<Surah> surahs,
    @Default('') String query,
  }) = SurahIndexLoaded;

  const factory SurahIndexState.error({required String message}) = SurahIndexError;
}
