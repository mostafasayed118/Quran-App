import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    audioRootResolver: defaultAudioRootResolver,
    citiesLoader: defaultCitiesLoader,
  );
  runApp(const QuranYahdiApp());
}
