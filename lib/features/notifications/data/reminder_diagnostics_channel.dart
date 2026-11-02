import 'package:flutter/services.dart';

import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';

/// The Android implementation of [ReminderDiagnostics].
///
/// The Kotlin side is `MainActivity.configureFlutterEngine`: the platform
/// holds the only truthful answer to all three questions (a Dart-side guess
/// from the plugin's cached state would go stale the moment the user revokes
/// a permission in the system settings).
///
/// Failure semantics — the whole point of this class:
/// - a permission read that fails reports "no issue" (`true`). Accusing the
///   device of blocking reminders because a probe failed would state something
///   false about the user's phone (the same discipline the notification
///   binding follows for a queued — not refused — permission);
/// - a battery read that fails reports `null`, i.e. "cannot report", which the
///   settings section renders as an instruction instead of a verdict;
/// - the two open actions report `false` when no screen was shown, so the
///   caller never claims it took the user somewhere it did not.
class ReminderDiagnosticsChannel implements ReminderDiagnostics {
  const ReminderDiagnosticsChannel();

  static const MethodChannel _channel =
      MethodChannel('quran_yahdi/reminder_diagnostics');

  @override
  Future<bool> notificationsEnabled() async =>
      await _read<bool>('notificationsEnabled') ?? true;

  @override
  Future<bool> exactAlarmsAllowed() async =>
      await _read<bool>('exactAlarmsAllowed') ?? true;

  @override
  Future<bool?> batteryOptimizationIgnored() =>
      _read<bool>('batteryOptimizationIgnored');

  @override
  Future<bool> openBatteryOptimizationSettings() async =>
      await _read<bool>('openBatteryOptimizationSettings') ?? false;

  @override
  Future<bool> openExactAlarmSettings() async =>
      await _read<bool>('openExactAlarmSettings') ?? false;

  /// One platform read; null for every "cannot answer" failure.
  ///
  /// [MissingPluginException] covers the platforms and the test hosts that
  /// have no handler for this channel — the diagnostics are Android-only, so
  /// "no handler" is a normal state, not an error.
  Future<T?> _read<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
