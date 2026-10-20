import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/azkar_repository.dart';

part 'azkar_state.freezed.dart';

@freezed
sealed class AzkarState with _$AzkarState {
  const factory AzkarState.loading() = AzkarLoading;

  /// Load failed (a repository read threw): the screen shows the localized
  /// error pane instead of hanging on [AzkarState.loading] forever.
  const factory AzkarState.failed() = AzkarFailed;

  const factory AzkarState.browsing({
    @Default(<AzkarCollection>[]) List<AzkarCollection> collections,
    @Default('') String query,
    @Default(<AzkarSearchHit>[]) List<AzkarSearchHit> searchResults,
    @Default(false) bool searchHasMore,
  }) = AzkarBrowsing;

  const factory AzkarState.reciting({
    required AzkarCollection collection,
    @Default(<int>[]) List<int> remaining,
  }) = AzkarReciting;
}
