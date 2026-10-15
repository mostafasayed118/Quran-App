import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/azkar_repository.dart';

part 'azkar_state.freezed.dart';

@freezed
sealed class AzkarState with _$AzkarState {
  const factory AzkarState.loading() = AzkarLoading;

  const factory AzkarState.browsing({
    @Default(<AzkarCollection>[]) List<AzkarCollection> collections,
  }) = AzkarBrowsing;

  const factory AzkarState.reciting({
    required AzkarCollection collection,
    @Default(<int>[]) List<int> remaining,
  }) = AzkarReciting;
}
