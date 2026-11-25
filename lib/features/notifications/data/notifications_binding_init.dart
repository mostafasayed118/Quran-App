part of 'notifications_binding.dart';

/// The kernel boot id, readable by the app on Android (verified on the
/// A16 emulator with the debug app's UID). `/proc/uptime` is NOT readable and
/// was rejected as a stamp. Null on platforms without the file: a null stamp
/// is never trusted across processes, so the cost is one re-apply per process.
String? _readBootId() {
  try {
    final value = File('/proc/sys/kernel/random/boot_id')
        .readAsStringSync()
        .trim();
    return value.isEmpty ? null : value;
  } on Object {
    return null;
  }
}

extension NotificationsBindingInit on NotificationsBinding {
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
          android: AndroidInitializationSettings(
            NotificationsBinding.defaultIcon,
          ),
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
          NotificationsBinding.channelId,
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
      _forceNextApply = await _previousExitClearedAlarms();
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
      // and the queued permission requests so neither survives as a stale
      // wish that will never be fulfilled.
      _pendingPlan = null;
      _pendingPermission = false;
      _pendingExactAlarms = false;
      _pendingCancelPreAdhan = false;
      return;
    }
    try {
      final saved = await _store?.read();
      final bootId = _bootId();
      // A plan applied earlier in THIS boot is still on the OS. Android drops
      // every alarm at reboot (the manifest intentionally ships no plugin boot
      // receiver), so a snapshot from a previous boot must never suppress the
      // re-schedule the boot path exists for. A null stamp (old snapshot, or a
      // platform without the kernel file) is not trusted either.
      if (saved != null && bootId != null && saved.bootId == bootId) {
        _appliedPlan ??= saved.fingerprint;
        _appliedExact ??= saved.exact;
      }
    } on Object catch (error, stackTrace) {
      // A store hiccup must not disable reminders; it only costs one re-apply.
      appLog(
        'reminder plan restore failed',
        name: 'quran_yahdi/reminders',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
    await _drainPending();
  }

  /// Applies what arrived while the plugin was not ready.
  ///
  /// The permission requests go first (an alarm registered before the OS
  /// permission is granted never shows up), then the plan — through the very
  /// same path a normal [scheduleAll] uses, so the plan-fingerprint dedupe
  /// applies to it as well. Nothing here throws: the queued work is
  /// best-effort, exactly like the direct calls.
  Future<void> _drainPending() async {
    if (_pendingPermission) {
      _pendingPermission = false;
      await ensurePermissions();
    }
    if (_pendingExactAlarms) {
      _pendingExactAlarms = false;
      await ensureExactAlarms();
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

  /// True when the previous process ended in a way that clears the alarms.
  ///
  /// This is a helper signal, not the primary one: it is read once at `init`,
  /// so a force stop while this process stays alive is invisible to it, and
  /// some OEMs report a different reason. The live probe is the backstop.
  Future<bool> _previousExitClearedAlarms() async {
    final probe = _alarmProbe;
    if (probe == null) return false;
    try {
      final reason = await probe.lastExitReason();
      // ApplicationExitInfo: 10 USER_REQUESTED (force stop), 11 USER_STOPPED,
      // 13 OTHER (an OEM kill).
      return reason == '10' || reason == '11' || reason == '13';
    } on Object {
      return false;
    }
  }
}
