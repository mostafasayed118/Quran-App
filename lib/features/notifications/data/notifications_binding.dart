import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/l10n/platform_localizations.dart';
import 'package:quran_yahdi/core/platform/reminder_alarm_probe.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_plan_store.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show preAdhanReminderId, reminderAlarmIds, shouldRequestBootPermission;
import 'package:timezone/timezone.dart' as tz;

part 'notifications_binding_init.dart';
part 'notifications_binding_apply.dart';
part 'notifications_binding_posts.dart';

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
/// Failure semantics: init failure leaves reminders disabled (disclosed v1
/// behavior) and must never crash boot. It is no longer silent: the failure is
/// logged under `quran_yahdi/reminders` and reported through
/// [ReminderApplyHealth], so the settings readout can show that no alarm is
/// armed.
///
/// Init window: the plugin init runs BEHIND the first frame, so a reminder
/// plan (or a permission request) that arrives before the plugin is ready is
/// QUEUED, never dropped — [init] applies it as soon as the plugin is ready
/// and discards it when the init fails. Nothing on this path waits for the
/// plugin: a caller that awaited readiness would hang instead of queueing.
class NotificationsBinding extends ChangeNotifier
    implements ReminderSchedulerPort, PreAdhanCanceller, ReminderApplyHealth {
  NotificationsBinding({
    FlutterLocalNotificationsPlugin? plugin,
    ReminderPlanStore? store,
    String? Function()? bootId,
    ReminderAlarmProbe? alarmProbe,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _store = store,
       _bootId = bootId ?? _readBootId,
       _alarmProbe = alarmProbe;

  static const String channelId = 'quran_yahdi_reminders';

  /// Prefix of the "play the adhan" action id; the track id follows the colon.
  ///
  /// The track id rides on the action id because an action response carries
  /// only its own id back — the notification payload is already the routing
  /// tag ("prayer").
  static const String adhanPlayActionPrefix = 'adhan_play:';

  static const String defaultIcon = '@mipmap/ic_launcher';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Persists the applied plan across process starts (the 15-minute
  /// background isolate builds a new binding every run).
  final ReminderPlanStore? _store;

  /// Identifies the running boot; null when the platform does not expose one.
  ///
  /// A row in [_store] says "already on the OS" only while this value matches
  /// the one recorded with the plan. Android drops every alarm at reboot, so a
  /// restored fingerprint from a previous boot would otherwise suppress the
  /// re-schedule that the boot path exists for.
  final String? Function() _bootId;

  /// Asks the OS whether a scheduled alarm still exists (null in tests).
  final ReminderAlarmProbe? _alarmProbe;

  /// Set when the previous process ended in a way that clears alarms (force
  /// stop or an OEM kill). Cleared only after a successful apply, so a failed
  /// apply does not swallow the signal.
  bool _forceNextApply = false;

  bool _ready = false;
  NotificationDetails? _details;

  /// Channel identity cached from `init` so a per-reciter channel can be built
  /// while posting, with no BuildContext in scope.
  String _channelName = '';
  String? _channelDescription;

  /// Label for the "play the adhan" action, cached from `init`.
  String _playAdhanLabel = '';

  void Function(String trackId)? _onPlayAdhan;
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

  /// Whether an exact-alarm request arrived before the plugin was ready.
  /// Same contract as [_pendingPermission]: [init] drains it through
  /// [ensureExactAlarms].
  bool _pendingExactAlarms = false;

  /// Whether the plugin init has already failed.
  ///
  /// After a failed init the reminders stay disabled (the disclosed v1
  /// semantics), so a later request must not queue a plan that no init will
  /// ever apply — it is dropped, exactly as it was before the queueing
  /// change. Cleared when an init is attempted again.
  bool _initFailed = false;

  /// Whether the last plan write failed (or the plugin never became ready).
  ///
  /// The settings reliability card reads this through [ReminderApplyHealth]:
  /// every OS permission can be granted while the write itself throws, and
  /// without this flag the card would call that device healthy.
  bool _lastApplyFailed = false;

  @override
  bool get lastApplyFailed => _lastApplyFailed;

  /// Sets the flag and notifies the reliability card when it actually moves,
  /// so a failure during a mounted settings screen appears without a resume.
  void _setApplyFailed(bool value) {
    if (_lastApplyFailed == value) return;
    _lastApplyFailed = value;
    notifyListeners();
  }

  /// Whether a pre-adhan cancellation arrived before the plugin was ready.
  bool _pendingCancelPreAdhan = false;

  /// The fingerprint of the last plan this binding applied to the OS.
  ///
  /// A reload that produces the SAME plan (a city change that moves no
  /// reminder, a settings save that changes nothing) must not cancel and
  /// re-schedule every alarm — the platform round-trip is the expensive part
  /// and the alarms it would write are identical.
  String? _appliedPlan;

  /// The ids the last applied plan wrote, so a reminder removed from the plan
  /// (e.g. the pre-adhan id when the user turns it off) is still cleared.
  Set<int> _appliedPlanIds = const <int>{};

  /// The exact-alarm grant the applied plan was scheduled with.
  ///
  /// The grant changes the schedule MODE (exact vs inexact), not the plan, so
  /// it has to be part of the "already applied" test: granting the permission
  /// again must upgrade the alarms instead of being deduped away.
  bool? _appliedExact;

  /// The tail of the apply chain. A plan change reaches the binding from
  /// several callers (boot, settings, the prayer screen); the applies must
  /// never interleave, or a slower earlier plan would overwrite a newer one
  /// after both have already cleared the alarms.
  Future<void>? _applyQueue;

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
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final notifications = await android.requestNotificationsPermission();
        final exact = await android.requestExactAlarmsPermission();
        return notifications != false && exact != false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
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

  /// Requests the OS exact-alarm permission when the OS reports it missing.
  ///
  /// Fresh installs schedule their reminder plan while the permission is
  /// still denied — on some OEM devices those alarms then never deliver. This
  /// is the request path the enable actions call, once per enable action: the
  /// plugin's own API is used when it has one; the "Alarms & reminders"
  /// system screen is the documented fallback where it does not. Returns
  /// whether the OS allows exact alarms afterwards (a granted grant reports
  /// `true`). Never throws.
  @override
  Future<bool> ensureExactAlarms() async {
    if (!_ready) {
      // The plugin failed for good: no init is left that could perform the
      // request later — drop it instead of keeping a stale wish.
      if (_initFailed) return false;
      _pendingExactAlarms = true;
      return true;
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true;
      final exact = await android.canScheduleExactNotifications();
      if (exact == true) return true;
      return await android.requestExactAlarmsPermission() ?? false;
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
    await _joinApplyQueue(() => _applyPlan(reminders));
  }

  /// Clears the optional pre-adhan alarm.
  ///
  /// This is separate from the frozen 1/2/3 replace-all trio: the optional id
  /// is not in that set, so turning it off must clear it explicitly. A call
  /// made before the plugin is ready is queued (never dropped) and applied by
  /// [init]; the cancel joins the same apply chain as a plan so it cannot
  /// interleave with an in-flight schedule.
  @override
  Future<void> cancelPreAdhan() async {
    if (!_ready || _details == null) {
      if (_initFailed) return;
      _pendingCancelPreAdhan = true;
      return;
    }
    await _joinApplyQueue(_cancelPreAdhanNow);
  }

  /// A deterministic fingerprint of a reminder plan.
  ///
  /// Every field that changes what the platform must do belongs here — the
  /// adhan included: a plan that differs only in the chosen reciter must still
  /// be re-posted, or the user keeps hearing the previous sound until some
  /// unrelated change forces a re-schedule.
  @visibleForTesting
  static String planFingerprint(List<ScheduledReminder> reminders) {
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
        r.adhanId ?? '',
        // A plan that only flips the daily repeat changes what the platform
        // stores, so it must re-post.
        r.repeatsDaily ? 'daily' : 'once',
      ]) {
        fields.add('${value.length}:$value');
      }
    }
    return fields.join();
  }
}
