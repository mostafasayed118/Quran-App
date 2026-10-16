import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/di/injector.dart';
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
  runApp(const QuranYahdiApp());
}
