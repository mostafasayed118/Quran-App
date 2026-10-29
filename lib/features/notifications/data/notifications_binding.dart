import 'dart:ui' show Locale, VoidCallback;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show
        azkarReminderId,
        prayerReminderId,
        shouldRequestBootPermission,
        wirdReminderId;
import 'package:quran_yahdi/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

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
///
/// Init window: the plugin init runs BEHIND the first frame, so a reminder
/// plan (or a permission request) that arrives before the plugin is ready is
/// QUEUED, never dropped — [init] applies it as soon as the plugin is ready
/// and discards it when the init fails. Nothing on this path waits for the
/// plugin: a caller that awaited readiness would hang instead of queueing.
class NotificationsBinding implements ReminderSchedulerPort {
  NotificationsBinding({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'quran_yahdi_reminders';
  static const String defaultIcon = '@mipmap/ic_launcher';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;
  NotificationDetails? _details;
  VoidCallback? _onTap;
  void Function(String payload)? _onTapPayload;

  /// The plan that was requested while the plugin was not ready yet.
  ///
  /// The plugin init now runs BEHIND the first frame, so a reminder change
  /// made in the first seconds of the app's life reaches the binding before
  /// the plugin is ready. The plan is remembered here (last write wins) and
  /// applied by [init] the moment the plugin reports ready — it is never
  /// dropped, and the user never loses a change without a trace.
  List<ScheduledReminder>? _pendingPlan;

  /// Whether a permission request arrived before the plugin was ready.
  ///
  /// Remembered for the same reason as [_pendingPlan]; [init] performs it
  /// once the plugin is ready.
  bool _pendingPermission = false;

  /// Whether the plugin init has already failed.
  ///
  /// After a failed init the reminders stay disabled (the disclosed v1
  /// semantics), so a later request must not queue a plan that no init will
  /// ever apply — it is dropped, exactly as it was before the queueing
  /// change. Cleared when an init is attempted again.
  bool _initFailed = false;

  /// The fingerprint of the last plan this binding applied to the OS.
  ///
  /// A reload that produces the SAME plan (a city change that moves no
  /// reminder, a settings save that changes nothing) must not cancel and
  /// re-schedule every alarm — the platform round-trip is the expensive part
  /// and the alarms it would write are identical.
  String? _appliedPlan;

  /// The tail of the apply chain. A plan change reaches the binding from
  /// several callers (boot, settings, the prayer screen); the applies must
  /// never interleave, or a slower earlier plan would overwrite a newer one
  /// after both have already cleared the alarms.
  Future<void>? _applyQueue;

  /// One-time plugin init; safe to call repeatedly, never rethrows. A
  /// notification tap fires the injected `onTap` callback (payloadless taps)
  /// or `onTapPayload` when the tapped reminder carries a routing tag — the
  /// app layer wires both to the router, so this data class stays
  /// router-free.
  ///
  /// When the init succeeds, whatever arrived during the init window — a
  /// queued plan, a queued permission request — is applied here. When the
  /// init fails, the queue is discarded: reminders stay disabled (the
  /// disclosed v1 semantics) and no stale plan survives the failure.
  Future<void> init({
    VoidCallback? onTap,
    void Function(String payload)? onTapPayload,
  }) async {
    if (_ready) return;
    _onTap = onTap;
    _onTapPayload = onTapPayload;
    _initFailed = false;
    try {
      final loc = lookupAppLocalizations(const Locale('ar'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(defaultIcon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: onNotificationTap,
      );
      _details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          loc.appName,
          channelDescription: loc.reminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      _ready = true;
    } on Object {
      _ready = false;
      _initFailed = true;
      // A failed init leaves the reminders disabled — drop the queued plan
      // and the queued permission request so neither survives as a stale
      // wish that will never be fulfilled.
      _pendingPlan = null;
      _pendingPermission = false;
      return;
    }
    await _drainPending();
  }

  /// Applies what arrived while the plugin was not ready.
  ///
  /// The permission request goes first (an alarm registered before the OS
  /// permission is granted never shows up), then the plan — through the very
  /// same path a normal [scheduleAll] uses, so the plan-fingerprint dedupe
  /// applies to it as well. Nothing here throws: the queued work is
  /// best-effort, exactly like the direct calls.
  Future<void> _drainPending() async {
    if (_pendingPermission) {
      _pendingPermission = false;
      await ensurePermissions();
    }
    final plan = _pendingPlan;
    _pendingPlan = null;
    if (plan != null) {
      await scheduleAll(plan);
    }
  }

  /// Warm tap: a reminder carrying a payload routes through [init]'s
  /// `onTapPayload`; everything else keeps the default-launch callback.
  /// A payloaded tap with no payload callback falls back to the default too.
  void onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    final onTapPayload = _onTapPayload;
    if (payload != null && payload.isNotEmpty && onTapPayload != null) {
      onTapPayload(payload);
      return;
    }
    _onTap?.call();
  }

  /// Cold-start payload: the tapped notification's tag when the app was
  /// launched by a tap, else null. Never throws (best-effort v1); a null
  /// result keeps the existing default-launch behavior.
  Future<String?> launchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } on Object {
      return null;
    }
  }

  /// First-boot POST_NOTIFICATIONS grace (UX-FIX 2): requests once when the
  /// OS reports notifications currently disabled and the azkar toggle is on
  /// (a user who opted out is never re-prompted). Never throws.
  Future<void> requestBootPermission({required bool azkarEnabled}) async {
    if (!_ready) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      final enabled = await android.areNotificationsEnabled();
      if (!shouldRequestBootPermission(
        notificationsEnabled: enabled,
        azkarEnabled: azkarEnabled,
      )) {
        return;
      }
      await android.requestNotificationsPermission();
    } on Object {
      // Best-effort v1: a refused/failed boot grace must never crash boot.
    }
  }

  /// Requests the OS notification (+ exact-alarm) permissions.
  ///
  /// While the plugin is not ready yet, the request is remembered and
  /// performed by [init] as soon as the plugin is ready. Such a request is
  /// NOT a refusal: it is reported as granted, because nothing was refused —
  /// claiming a denial that never happened would state something false about
  /// the user's device (the same discipline the playback probe follows).
  ///
  /// Returns false only when the OS refused the request or the plugin is
  /// unavailable. Never throws.
  @override
  Future<bool> ensurePermissions() async {
    if (!_ready) {
      // The plugin failed for good: the reminders stay disabled and there is
      // no init left that could apply a queued request.
      if (_initFailed) return false;
      _pendingPermission = true;
      return true;
    }
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final notifications = await android.requestNotificationsPermission();
        final exact = await android.requestExactAlarmsPermission();
        return notifications != false && exact != false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Replace-all semantics: cancels the previously scheduled reminders, then
  /// schedules the given plan.
  ///
  /// While the plugin is not ready yet, the plan is remembered (last write
  /// wins) and applied by [init] once the plugin is ready — the plan is
  /// never dropped, so a city change or an azkar/wird toggle made during
  /// the init window still reaches the OS.
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    if (!_ready || _details == null) {
      // A failed init leaves the reminders disabled for good: drop the plan
      // instead of keeping a queue that no init will ever apply.
      if (_initFailed) return;
      _pendingPlan = List<ScheduledReminder>.of(reminders);
      return;
    }
    final previous = _applyQueue;
    final run = () async {
      if (previous != null) {
        try {
          await previous;
        } on Object {
          // _applyPlan swallows its own failures; keep the chain alive.
        }
      }
      await _applyPlan(reminders);
    }();
    _applyQueue = run;
    await run;
  }

  /// Cancels the previous reminder alarms and schedules [reminders].
  ///
  /// The clear is TARGETED: only the ids the planner owns are cancelled.
  /// A blanket `cancelAll()` would also wipe every other notification the
  /// app posted — most visibly the playback notification owned by
  /// `just_audio_background` — and this path runs at boot, on the prayer
  /// screen load, on a city change and on a settings save.
  ///
  /// The plan fingerprint skips the platform round-trip when the new plan
  /// schedules exactly the same alarms as the applied one.
  Future<void> _applyPlan(List<ScheduledReminder> reminders) async {
    final details = _details;
    if (details == null) return;
    final fingerprint = _planFingerprint(reminders);
    if (fingerprint == _appliedPlan) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      // The alarms are about to be cleared. From this point the old
      // fingerprint is a lie even if a later zonedSchedule throws.
      _appliedPlan = null;
      // All three planner ids go up front, so a reminder that is no longer
      // part of the new plan is still removed (replace-all semantics).
      for (final id in const <int>[
        prayerReminderId,
        azkarReminderId,
        wirdReminderId,
      ]) {
        await _plugin.cancel(id: id);
      }
      for (final reminder in reminders) {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          payload: reminder.payload,
          scheduledDate: tz.TZDateTime.from(reminder.fireAt.toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      }
      _appliedPlan = fingerprint;
    } on Object {
      // Best-effort v1: a failed schedule surfaces only in the device smoke.
    }
  }

  /// A deterministic fingerprint of a reminder plan: the reminders sorted by
  /// id, each with its fire instant and its visible copy.
  ///
  /// Two plans with the same fingerprint schedule exactly the same alarms, so
  /// the second one can skip the platform round-trip. The copy is part of the
  /// fingerprint on purpose: a renamed reciter changes what the shade shows
  /// and must therefore re-register the alarm.
  static String _planFingerprint(List<ScheduledReminder> reminders) {
    final sorted = [...reminders]..sort((a, b) => a.id.compareTo(b.id));
    // Length-prefixed fields: no separator can appear in the content, so the
    // flat encoding is unambiguous.
    final fields = <String>[];
    for (final r in sorted) {
      for (final value in <String>[
        '${r.id}',
        r.fireAt.toUtc().toIso8601String(),
        r.title,
        r.body ?? '',
        r.payload ?? '',
      ]) {
        fields.add('${value.length}:$value');
      }
    }
    return fields.join();
  }
}
