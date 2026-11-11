import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/l10n/platform_localizations.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_plan_store.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show preAdhanReminderId, reminderAlarmIds, shouldRequestBootPermission;
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
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _store = store;

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
    void Function(String trackId)? onPlayAdhan,
  }) async {
    if (_ready) return;
    _onTap = onTap;
    _onPlayAdhan = onPlayAdhan;
    _onTapPayload = onTapPayload;
    _initFailed = false;
    try {
      final loc = platformLocalizations();
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
        // iOS shows the alert with the system sound; the custom adhan clips are
        // Android raw resources, so iOS keeps the default sound (no .caf asset
        // is cleared for shipping yet).
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );
      // Cached so a per-reciter channel can be built at post time without a
      // BuildContext.
      _channelName = loc.appName;
      _channelDescription = loc.reminderChannelDescription;
      _playAdhanLabel = loc.adhanPlayAction;
      _ready = true;
      _setApplyFailed(false);
    } on Object catch (error, stackTrace) {
      _ready = false;
      _initFailed = true;
      _setApplyFailed(true);
      appLog(
        'notifications init failed',
        name: 'quran_yahdi/reminders',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      // A failed init leaves the reminders disabled — drop the queued plan
      // and the queued permission request so neither survives as a stale
      // wish that will never be fulfilled.
      _pendingPlan = null;
      _pendingPermission = false;
      _pendingCancelPreAdhan = false;
      return;
    }
    try {
      final saved = await _store?.read();
      if (saved != null) {
        // A plan applied before this process started is already on the OS;
        // the in-memory value wins only when this binding has a newer one.
        _appliedPlan ??= saved.fingerprint;
        _appliedExact ??= saved.exact;
      }
    } on Object catch (error, stackTrace) {
      // A store hiccup must not disable reminders; it only costs one re-apply.
      appLog('reminder plan restore failed',
          name: 'quran_yahdi/reminders',
          error: error.runtimeType,
          stackTrace: stackTrace);
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
    if (_pendingCancelPreAdhan) {
      _pendingCancelPreAdhan = false;
      await _cancelPreAdhanNow();
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
    // An action button wins over the tap payload: "play the adhan" is an
    // explicit verb, not navigation.
    final actionId = response.actionId;
    final onPlayAdhan = _onPlayAdhan;
    if (actionId != null &&
        actionId.startsWith(adhanPlayActionPrefix) &&
        onPlayAdhan != null) {
      final trackId = actionId.substring(adhanPlayActionPrefix.length);
      if (trackId.isNotEmpty) {
        onPlayAdhan(trackId);
        return;
      }
    }
    final payload = response.payload;
    final onTapPayload = _onTapPayload;
    if (payload != null && payload.isNotEmpty && onTapPayload != null) {
      onTapPayload(payload);
      return;
    }
    _onTap?.call();
  }

  /// The action id of the notification that cold-started the app, when it was
  /// an "play adhan" action; null otherwise. Never throws.
  Future<String?> launchAdhanActionId() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final actionId = details.notificationResponse?.actionId;
      if (actionId == null || !actionId.startsWith(adhanPlayActionPrefix)) {
        return null;
      }
      final trackId = actionId.substring(adhanPlayActionPrefix.length);
      return trackId.isEmpty ? null : trackId;
    } on Object {
      return null;
    }
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

  /// Joins the shared apply chain: waits for every in-flight plan write
  /// before running [body], then stores [body]'s future as the new tail so
  /// callers cannot interleave. Plan bodies swallow their own failures; a
  /// throwing body is tolerated so the chain never dies.
  Future<void> _joinApplyQueue(Future<void> Function() body) async {
    final previous = _applyQueue;
    final run = () async {
      if (previous != null) {
        try {
          await previous;
        } on Object {
          // A failing body cannot interleave the chain; keep it alive.
        }
      }
      await body();
    }();
    _applyQueue = run;
    await run;
  }

  Future<void> _cancelPreAdhanNow() async {
    try {
      await _plugin.cancel(id: preAdhanReminderId);
    } on Object {
      // Best-effort, like every other reminder write; keep the fingerprint so
      // a later re-plan retries the cancel.
      return;
    }
    final hadPreAdhan = _appliedPlanIds.contains(preAdhanReminderId);
    if (hadPreAdhan) {
      _appliedPlan = null;
      await _store?.clear();
    }
    _appliedPlanIds = <int>{..._appliedPlanIds}..remove(preAdhanReminderId);
  }

  /// The notification details to post [reminder] with.
  ///
  /// One Android channel per reciter is deliberate: the OS freezes a channel's
  /// sound at creation, so a single shared channel would leave every existing
  /// user permanently stuck on the first adhan they ever heard. Selecting an
  /// adhan selects a channel and no channel is ever mutated. The channel is
  /// created implicitly on first post, so at most `kAdhanCatalog.length`
  /// channels can ever exist.
  ///
  /// [fallback] is today's shared channel, used by azkar, wird and the
  /// pre-adhan heads-up — only the prayer reminder carries an adhan.
  NotificationDetails _detailsFor(
    ScheduledReminder reminder,
    NotificationDetails fallback,
  ) {
    final id = reminder.adhanId;
    if (id == null) return fallback;
    final track = adhanById(id);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        adhanChannelId(track),
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(track.clipResource),
        actions: <AndroidNotificationAction>[
          // The track id rides on the action id: the notification payload is
          // already the routing tag ("prayer"), and an action response carries
          // only its own id back.
          AndroidNotificationAction(
            '$adhanPlayActionPrefix${track.id}',
            _playAdhanLabel,
            // Must bring the app up: at prayer time it is usually not running,
            // and an action that never reaches Dart is a silent no-op.
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
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
    try {
      // The exact-alarm grant is part of "already applied": it decides the
      // schedule MODE, not the plan, so a fingerprint match alone must not skip
      // the re-apply — that is how a newly granted permission upgrades the
      // alarms from inexact to exact.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final fingerprint = planFingerprint(reminders);
      if (fingerprint == _appliedPlan && exact == _appliedExact) return;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      // The alarms are about to be cleared. From this point the old
      // fingerprint is a lie even if a later zonedSchedule throws.
      _appliedPlan = null;
      // Clear EVERY id the planner can write, not just the ones this plan
      // contains: a reminder the user turned off in an earlier session has to
      // stop, and the binding keeps no memory of that session. The set is
      // fixed and small (the rolling window), so this stays a targeted cancel
      // — a blanket `cancelAll()` would wipe the playback notification owned
      // by `just_audio_background`.
      await _inChunks(reminderAlarmIds(), (id) => _plugin.cancel(id: id));
      _appliedPlanIds = <int>{
        ..._appliedPlanIds,
        ...reminders.map((reminder) => reminder.id),
      };
      final scheduleFailures = <Object>[];
      await _inChunks(reminders, (reminder) async {
        try {
          await _plugin.zonedSchedule(
            id: reminder.id,
            title: reminder.title,
            body: reminder.body,
            payload: reminder.payload,
            scheduledDate: tz.TZDateTime.from(reminder.fireAt.toUtc(), tz.UTC),
            notificationDetails: _detailsFor(reminder, details),
            androidScheduleMode: mode,
            // Azkar and wird fire at a fixed clock time, so the OS can repeat
            // them forever and restore them after a reboot with no app start.
            // Prayer reminders stay one-shot: their time moves every day.
            matchDateTimeComponents:
                reminder.repeatsDaily ? DateTimeComponents.time : null,
          );
        } on Object catch (error, stackTrace) {
          // One rejected alarm must not abort the rest of the window: the
          // user would silently lose every reminder after it.
          scheduleFailures.add(error);
          appLog('reminder schedule failed',
              name: 'quran_yahdi/reminders',
              error: error.runtimeType,
              stackTrace: stackTrace);
        }
      });
      if (scheduleFailures.isNotEmpty) {
        _setApplyFailed(true);
        return;
      }
      _appliedPlan = fingerprint;
      _appliedExact = exact;
      _setApplyFailed(false);
      await _store?.write(
        ReminderPlanSnapshot(fingerprint: fingerprint, exact: exact),
      );
    } on Object catch (error, stackTrace) {
      // Best-effort: a failed schedule must not crash the caller, but it can
      // no longer be silent — the reliability card and logcat both read it.
      _setApplyFailed(true);
      appLog(
        'reminder plan apply failed',
        name: 'quran_yahdi/reminders',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
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

  /// Runs [action] over [items] with bounded concurrency.
  ///
  /// The platform channel is the bottleneck in an apply: a full plan is ~88
  /// cancels plus ~74 schedules, and awaiting them strictly one at a time
  /// keeps the call on the channel for its full serial latency. Eight in
  /// flight collapses that without flooding the channel. The id sets are
  /// unchanged, and every operation here is per-id, so order does not matter.
  Future<void> _inChunks<T>(
    Iterable<T> items,
    Future<void> Function(T item) action, {
    int concurrency = 8,
  }) async {
    final queue = items.toList();
    for (var start = 0; start < queue.length; start += concurrency) {
      final end = start + concurrency < queue.length
          ? start + concurrency
          : queue.length;
      await Future.wait([
        for (var i = start; i < end; i++) action(queue[i]),
      ]);
    }
  }
}
