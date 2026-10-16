import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/di/injector.dart';
import 'features/notifications/data/notifications_binding.dart';
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
  await BackgroundInitGuard.attempt(
    () => JustAudioBackground.init(
      androidNotificationChannelId:
          'com.mostafasayed.quranyahdi.channel.audio',
      androidNotificationChannelName: 'تلاوات قرآن يَهدي',
      androidNotificationOngoing: true,
    ),
  );
  await getIt<NotificationsBinding>().init();
  unawaited(_requestBootNotificationGrace());
  unawaited(runBootReminderSchedule());
  runApp(const QuranYahdiApp());
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
