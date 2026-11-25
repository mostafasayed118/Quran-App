part of 'notifications_binding.dart';

extension NotificationsBindingPosts on NotificationsBinding {
  /// Warm tap: a reminder carrying a payload routes through [init]'s
  /// `onTapPayload`; everything else keeps the default-launch callback.
  /// A payloaded tap with no payload callback falls back to the default too.
  void onNotificationTap(NotificationResponse response) {
    // An action button wins over the tap payload: "play the adhan" is an
    // explicit verb, not navigation.
    final actionId = response.actionId;
    final onPlayAdhan = _onPlayAdhan;
    if (actionId != null &&
        actionId.startsWith(NotificationsBinding.adhanPlayActionPrefix) &&
        onPlayAdhan != null) {
      final trackId = actionId.substring(
        NotificationsBinding.adhanPlayActionPrefix.length,
      );
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
      if (actionId == null ||
          !actionId.startsWith(NotificationsBinding.adhanPlayActionPrefix)) {
        return null;
      }
      final trackId = actionId.substring(
        NotificationsBinding.adhanPlayActionPrefix.length,
      );
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
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
            '${NotificationsBinding.adhanPlayActionPrefix}${track.id}',
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
}
