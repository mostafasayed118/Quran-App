import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/surah_summary.dart';

part 'surah_index_state.freezed.dart';

@freezed
sealed class SurahIndexState with _$SurahIndexState {
  const factory SurahIndexState.loading() = SurahIndexLoading;

  const factory SurahIndexState.ready({
    @Default(<SurahSummary>[]) List<SurahSummary> surahs,
    @Default('') String query,
  }) = SurahIndexReady;

  const factory SurahIndexState.failed() = SurahIndexFailed;
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef SurahIndexLoaded = SurahIndexReady;

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef SurahIndexError = SurahIndexFailed;

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension SurahIndexFailedMessage on SurahIndexFailed {
  String get message => 'failed';
}
