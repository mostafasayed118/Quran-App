import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/router.dart';
import 'core/di/injector.dart';
import 'core/l10n/platform_localizations.dart';
import 'features/notifications/data/notifications_binding.dart';
import 'features/notifications/data/reminder_planner.dart'
    show azkarReminderPayload, prayerReminderPayload;
import 'features/notifications/data/reminder_settings.dart';
import 'features/recitation/playback/background_init_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    audioRootResolver: defaultAudioRootResolver,
    citiesLoader: defaultCitiesLoader,
    azkarLoader: defaultAzkarLoader,
    duasLoader: defaultDuasLoader,
    ruqyahLoader: defaultRuqyahLoader,
    asmaLoader: defaultAsmaLoader,
    libraryCatalogLoader: defaultLibraryCatalogLoader,
    libraryRootResolver: defaultLibraryRootResolver,
  );
  final loc = platformLocalizations();
  await BackgroundInitGuard.attempt(
    () => JustAudioBackground.init(
      androidNotificationChannelId: 'com.mostafasayed.quranyahdi.channel.audio',
      androidNotificationChannelName:
          '${loc.recitationsTitle} — ${loc.appName}',
      androidNotificationOngoing: true,
    ),
  );
  await getIt<NotificationsBinding>().init(
    onTap: () => AppRouter.router.go('/home'),
    onTapPayload: (payload) =>
        AppRouter.router.go(reminderRouteFor(payload) ?? '/home'),
  );
  unawaited(_requestBootNotificationGrace());
  unawaited(_openReminderLaunchTarget());
  unawaited(runBootReminderSchedule());
  runApp(const QuranYahdiApp());
}

/// Tap-target route for a reminder payload; null for unknown/absent payloads
/// (the caller falls back to `/home`). Warm taps and cold launches share it.
String? reminderRouteFor(String? payload) => switch (payload) {
      prayerReminderPayload => '/prayer-times',
      azkarReminderPayload => '/azkar',
      _ => null,
    };

/// Cold-start routing: when the app was launched by tapping a reminder, land
/// on its own screen instead of home. Best-effort — a launch-details read
/// failure never breaks boot (W7b discipline).
Future<void> _openReminderLaunchTarget() async {
  try {
    final route =
        reminderRouteFor(await getIt<NotificationsBinding>().launchPayload());
    if (route == null) return;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => AppRouter.router.go(route));
  } on Object {
    // Disclosed v1: silent cold-launch routing failure.
  }
}

/// First-boot POST_NOTIFICATIONS grace (UX-FIX 2): run once after plugin
/// init, only for an azkar-reminders opt-in user with notifications off at
/// the OS level. Best-effort — a DB or plugin failure never breaks boot.
Future<void> _requestBootNotificationGrace() async {
  try {
    final azkarEnabled = await getIt<ReminderSettings>().azkarEnabled();
    await getIt<NotificationsBinding>()
        .requestBootPermission(azkarEnabled: azkarEnabled);
  } on Object {
    // Disclosed v1: silent boot-grace failure.
  }
}
