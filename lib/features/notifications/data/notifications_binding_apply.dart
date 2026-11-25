part of 'notifications_binding.dart';

extension NotificationsBindingApply on NotificationsBinding {
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

  /// True while the OS still holds the next scheduled alarms.
  ///
  /// Two upcoming alarms are sampled, and ANY missing one triggers a rearm —
  /// there is no tolerance for a single legitimate disappearance. A rearm is
  /// idempotent, so a spurious rearm is cheap next to a missed reminder. A
  /// probe error counts as "missing" for the same reason.
  Future<bool> _alarmsStillScheduled(List<ScheduledReminder> reminders) async {
    final probe = _alarmProbe;
    if (probe == null) return true;
    final now = DateTime.now();
    final upcoming = reminders.where((r) => r.fireAt.isAfter(now)).toList()
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    for (final reminder in upcoming.take(2)) {
      try {
        if (!await probe.alarmExists(reminder.id)) return false;
      } on MissingPluginException {
        // A background isolate (the scheduled worker) has no MainActivity to
        // answer the channel: absence of the channel is not evidence that the
        // alarms are gone, so it must not force a re-arm. Logged so a
        // foreground registration failure is not silent.
        appLog(
          'reminder alarm probe unavailable in this isolate',
          name: 'quran_yahdi/reminders',
        );
        return true;
      } on Object catch (error, stackTrace) {
        appLog(
          'reminder alarm probe failed',
          name: 'quran_yahdi/reminders',
          error: error.runtimeType,
          stackTrace: stackTrace,
        );
        return false;
      }
    }
    return true;
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
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      final fingerprint = NotificationsBinding.planFingerprint(reminders);
      if (_forceNextApply) {
        appLog(
          'reminder rearm',
          name: 'quran_yahdi/reminders',
          error: 'exit-reason',
        );
      } else if (fingerprint == _appliedPlan && exact == _appliedExact) {
        // The fingerprint is only trustworthy while the OS still holds the
        // alarms; force stop clears them without changing anything the
        // fingerprint can see.
        if (await _alarmsStillScheduled(reminders)) return;
        appLog(
          'reminder rearm',
          name: 'quran_yahdi/reminders',
          error: 'alive-check',
        );
      }
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
            matchDateTimeComponents: reminder.repeatsDaily
                ? DateTimeComponents.time
                : null,
          );
        } on Object catch (error, stackTrace) {
          // One rejected alarm must not abort the rest of the window: the
          // user would silently lose every reminder after it.
          scheduleFailures.add(error);
          appLog(
            'reminder schedule failed',
            name: 'quran_yahdi/reminders',
            error: error.runtimeType,
            stackTrace: stackTrace,
          );
        }
      });
      if (scheduleFailures.isNotEmpty) {
        _setApplyFailed(true);
        return;
      }
      // Persist BEFORE consuming the rearm signal: if the write throws, the
      // in-memory markers must still say "not applied" so the next attempt
      // retries instead of trusting a fingerprint that never reached disk.
      await _store?.write(
        ReminderPlanSnapshot(
          fingerprint: fingerprint,
          exact: exact,
          bootId: _bootId(),
        ),
      );
      _forceNextApply = false;
      _appliedPlan = fingerprint;
      _appliedExact = exact;
      _setApplyFailed(false);
    } on Object catch (error, stackTrace) {
      // Best-effort: a failed schedule must not crash the caller, but it can
      // no longer be silent — the reliability card reads it; logcat only in
      // debug/profile builds (appLog is silent in release).
      _setApplyFailed(true);
      appLog(
        'reminder plan apply failed',
        name: 'quran_yahdi/reminders',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
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
      await Future.wait([for (var i = start; i < end; i++) action(queue[i])]);
    }
  }
}
