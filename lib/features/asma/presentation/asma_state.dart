import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/asma_repository.dart';

part 'asma_state.freezed.dart';

@freezed
sealed class AsmaState with _$AsmaState {
  const factory AsmaState.loading() = AsmaLoading;

  /// Load failed (a repository read threw): the screen shows the localized
  /// error pane instead of hanging on [AsmaState.loading] forever.
  const factory AsmaState.failed() = AsmaFailed;

  const factory AsmaState.ready({
    @Default(<AsmaName>[]) List<AsmaName> names,
    @Default(null) AsmaName? selected,
  }) = AsmaReady;
}
