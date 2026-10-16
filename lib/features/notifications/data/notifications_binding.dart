import 'dart:ui' show Locale;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// The ONE file that touches the flutter_local_notifications plugin (W7b
/// headless law): planned reminders arrive as plain data and UI texts arrive
/// pre-composed, so nothing else imports the plugin and `flutter test` never
/// reaches a platform channel.
///
/// Exact alarms: `zonedSchedule` runs with `exactAllowWhileIdle` when the OS
/// reports exact-alarm capability, else `inexactAllowWhileIdle`
/// (drift-tolerant v1 — PM ruling); [ensurePermissions] drives the Android 13
/// POST_NOTIFICATIONS + Android 14 SCHEDULE_EXACT_ALARM runtime flows.
/// API quotes (pub cache, flutter_local_notifications 22.3.2):
/// `requestNotificationsPermission()`, `requestExactAlarmsPermission()`,
/// `canScheduleExactNotifications()` on `AndroidFlutterLocalNotificationsPlugin`;
/// `zonedSchedule({required int id, required TZDateTime scheduledDate, ...})`.
///
/// Time zone: resolving the device's IANA name would need a third package
/// (flutter_timezone — outside the 2-package intake), so fire instants are
/// mapped as `TZDateTime.from(fireAt.toUtc(), tz.UTC)`. The Android side parses
/// `LocalDateTime(scheduledDateTime) + ZoneId.of('Etc/UTC')` (verified in the
/// plugin's Java source), reproducing the exact absolute instant — the wall
/// clock zone database is never needed.
///
/// Failure semantics: init failure leaves reminders silently disabled
/// (disclosed v1 behavior) and must never crash boot (device smoke enforces).
class NotificationsBinding implements ReminderScheduler {
  NotificationsBinding({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'quran_yahdi_reminders';
  static const String defaultIcon = '@mipmap/ic_launcher';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;
  NotificationDetails? _details;

  /// One-time plugin init; safe to call repeatedly, never rethrows.
  Future<void> init() async {
    if (_ready) return;
    try {
      final loc = lookupAppLocalizations(const Locale('ar'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(defaultIcon),
        ),
      );
      _details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          loc.appName,
          channelDescription: loc.reminderAzkar,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      _ready = true;
    } on Object {
      _ready = false;
    }
  }

  @override
  Future<bool> ensurePermissions() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      final notifications = await android.requestNotificationsPermission();
      final exact = await android.requestExactAlarmsPermission();
      return notifications != false && exact != false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    final details = _details;
    if (!_ready || details == null) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      await _plugin.cancelAll();
      for (final reminder in reminders) {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.fireAt.toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      }
    } on Object {
      // Best-effort v1: a failed schedule surfaces only in the device smoke.
    }
  }
}
