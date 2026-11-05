/// Reminder reliability diagnostics: why the OS may suppress the prayer or
/// azkar reminders this app scheduled.
///
/// The port lives in `core/domain/` on purpose: the settings screen renders
/// the verdict and the notifications feature owns the platform channel that
/// reads it, so `core` is the only layer both are allowed to import (a
/// feature-to-feature edge is an architecture decision, and a presentation
/// class never reaches into another feature's `data/`).
library;

/// One reason a scheduled reminder may never reach the user.
enum ReminderIssue {
  /// POST_NOTIFICATIONS is off (Android 13+, or alerts were disabled): the
  /// alarm fires, but the shade shows nothing.
  notificationsOff,

  /// The OS refuses exact alarms (Android 14+ can revoke
  /// `SCHEDULE_EXACT_ALARM`): the reminder may arrive minutes late.
  exactAlarmsOff,

  /// The OEM battery saver may kill the app before the alarm fires — the
  /// Infinix/Tecno/Xiaomi failure this diagnostics section exists for.
  batteryRestricted,

  /// The OS refused the last plan write, so none of the alarms are armed.
  ///
  /// This is the one issue the device permissions cannot reveal: they can all
  /// be granted while `zonedSchedule` still throws. [ReminderApplyHealth]
  /// carries the last attempt's outcome so the readout can say it.
  scheduleFailed,
}

/// The issues worth showing for the given device state, in display order.
///
/// [batteryOptimizationIgnored] is null when the platform cannot report it
/// (an OEM ROM without the API). That is NOT an issue: the caller shows the
/// "check it yourself" instruction instead of claiming a restriction that was
/// never observed.
List<ReminderIssue> diagnoseReminders({
  required bool notificationsEnabled,
  required bool exactAlarmsAllowed,
  required bool? batteryOptimizationIgnored,
  bool scheduleFailed = false,
}) {
  return [
    if (!notificationsEnabled) ReminderIssue.notificationsOff,
    if (!exactAlarmsAllowed) ReminderIssue.exactAlarmsOff,
    if (scheduleFailed) ReminderIssue.scheduleFailed,
    if (batteryOptimizationIgnored == false) ReminderIssue.batteryRestricted,
  ];
}

/// The last reminder-plan write's outcome, for the reliability readout.
///
/// Kept separate from [ReminderDiagnostics] on purpose: the diagnostics port
/// reads the OS, while this one reports the app's own last attempt. The
/// notifications binding owns the truth; a host without one simply omits the
/// row.
abstract interface class ReminderApplyHealth {
  /// True when the most recent plan write threw (or the plugin never became
  /// ready), so no alarm from that plan is armed.
  bool get lastApplyFailed;
}

/// Cross-feature seam in front of the platform's reminder-health checks.
///
/// Implementations must never throw: this is an advisory readout, so an
/// unreadable state degrades to "no issue" (a failed probe must not accuse the
/// user's device) and an unreadable battery state degrades to null ("cannot
/// report"). Same discipline as the other reminder ports: nothing here is
/// allowed to take a screen down.
abstract interface class ReminderDiagnostics {
  /// Whether the OS currently lets this app post notifications.
  Future<bool> notificationsEnabled();

  /// Whether the OS currently allows exact alarms (true below Android 12,
  /// where the restriction does not exist).
  Future<bool> exactAlarmsAllowed();

  /// Whether the OS exempts this app from battery optimisation; null when the
  /// platform cannot report it.
  Future<bool?> batteryOptimizationIgnored();

  /// Opens the system battery-optimisation screen; false when no activity
  /// handled the intent.
  Future<bool> openBatteryOptimizationSettings();

  /// Opens the system exact-alarm screen; false when no activity handled the
  /// intent (or the OS has no such screen).
  Future<bool> openExactAlarmSettings();
}
