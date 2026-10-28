import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/reminders.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.loading() = SettingsLoading;

  const factory SettingsState.failed() = SettingsFailed;

  const factory SettingsState.ready({
    @Default(true) bool prayerEnabled,
    @Default(false) bool azkarEnabled,
    @Default(defaultAzkarTimeHm) String azkarTimeHm,
    @Default(false) bool wirdEnabled,
    @Default(defaultWirdTimeHm) String wirdTimeHm,
    @Default(false) bool azkarPermissionDenied,
    @Default(false) bool wirdPermissionDenied,
  }) = SettingsReady;
}

extension SettingsReadyPermission on SettingsReady {
  bool get permissionDenied => azkarPermissionDenied || wirdPermissionDenied;
}
