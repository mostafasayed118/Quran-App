import 'package:flutter/services.dart';

/// What the OS currently holds for the scheduled reminders.
///
/// The binding trusts a plan fingerprint within one boot, but an external
/// clear (force stop, an OEM battery manager) removes the alarms without
/// changing anything the fingerprint can see. This probe asks the platform
/// whether a given notification id still has its `PendingIntent` registered.
///
/// The Android side reconstructs that `PendingIntent` identity using the
/// private shape of **flutter_local_notifications 22.3.2**: request code =
/// notification id, component = `ScheduledNotificationReceiver`, intent with
/// no action or data. That shape is not public API. `plugin_version_pin_test`
/// fails the suite if the locked version moves, so an upgrade forces a fresh
/// source check and a fresh device probe before this bridge can be trusted.
abstract interface class ReminderAlarmProbe {
  /// True when the OS still holds the alarm with [notificationId].
  ///
  /// Throws when the platform cannot answer; the caller treats that as
  /// "unknown" and re-arms, which is safe because a re-arm is idempotent.
  Future<bool> alarmExists(int notificationId);

  /// The reason the previous process ended, as the platform reports it, or
  /// null when the platform cannot tell.
  Future<String?> lastExitReason();
}

/// The production bridge to the Android diagnostics channel.
class PlatformReminderAlarmProbe implements ReminderAlarmProbe {
  /// Creates the probe over the app's diagnostics channel.
  const PlatformReminderAlarmProbe();

  static const MethodChannel channel =
      MethodChannel('quran_yahdi/reminder_diagnostics');

  @override
  Future<bool> alarmExists(int notificationId) async {
    final exists = await channel.invokeMethod<bool>(
      'alarmExists',
      <String, Object?>{'id': notificationId},
    );
    // "No verdict" is NOT the same as "alarm missing". Throwing lets the
    // caller's unknown-handling log it and re-arm; a silent false would
    // erase that distinction.
    if (exists == null) {
      throw StateError('alarmExists returned no verdict for $notificationId');
    }
    return exists;
  }

  @override
  Future<String?> lastExitReason() =>
      channel.invokeMethod<String>('lastExitReason');
}
