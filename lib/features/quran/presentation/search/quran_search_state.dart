import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/quran_search_source.dart';

part 'quran_search_state.freezed.dart';

@freezed
sealed class QuranSearchState with _$QuranSearchState {
  const factory QuranSearchState.loading() = QuranSearchLoading;

  const factory QuranSearchState.ready({
    required String query,
    required List<QuranSearchHit> hits,
    required int total,
    required bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool moreFailed,
  }) = QuranSearchReady;

  const factory QuranSearchState.failed() = QuranSearchFailed;
}
