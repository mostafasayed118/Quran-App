import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/prayer_config.dart';

part 'prayer_config_state.freezed.dart';

/// The prayer settings screen state.
@freezed
sealed class PrayerConfigState with _$PrayerConfigState {
  /// The initial load is running.
  const factory PrayerConfigState.loading() = PrayerConfigLoading;

  /// The load failed; the screen offers a retry.
  const factory PrayerConfigState.failed() = PrayerConfigFailed;

  /// The persisted configuration is available.
  const factory PrayerConfigState.ready(PrayerConfig config) =
      PrayerConfigReady;
}
