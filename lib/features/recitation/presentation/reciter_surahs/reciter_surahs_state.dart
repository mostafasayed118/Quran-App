import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/reciter_info.dart';

part 'reciter_surahs_state.freezed.dart';

@freezed
sealed class ReciterSurahsState with _$ReciterSurahsState {
  const factory ReciterSurahsState.loading() = ReciterSurahsLoading;

  const factory ReciterSurahsState.ready({
    required ReciterInfo row,
    @Default(<int>[]) List<int> surahNumbers,
    @Default(<int, String>{}) Map<int, String> names,
    @Default(<int, String>{}) Map<int, String> previews,
  }) = ReciterSurahsReady;

  const factory ReciterSurahsState.failed() = ReciterSurahsFailed;
}
