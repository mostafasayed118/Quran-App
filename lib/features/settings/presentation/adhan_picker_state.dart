import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/adhan_catalog.dart';

part 'adhan_picker_state.freezed.dart';

/// The adhan picker's state.
///
/// [previewingId] lives here rather than in the widget so that the "stop the
/// previous preview before starting the next" rule is one well-tested place
/// instead of a per-row local flag that can disagree with the player.
@freezed
sealed class AdhanPickerState with _$AdhanPickerState {
  /// The first load is running.
  const factory AdhanPickerState.loading() = AdhanPickerLoading;

  /// The load failed; the screen offers a retry.
  const factory AdhanPickerState.failed() = AdhanPickerFailed;

  /// The stored choices are known.
  const factory AdhanPickerState.ready({
    @Default(kDefaultAdhanId) String adhanId,
    String? fajrAdhanId,
    String? previewingId,
  }) = AdhanPickerReady;
}
