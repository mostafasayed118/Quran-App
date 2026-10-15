import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const QuranYahdiApp());
}
