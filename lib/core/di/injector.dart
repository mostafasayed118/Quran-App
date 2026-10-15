import 'package:get_it/get_it.dart';

import '../db/app_database.dart';

final getIt = GetIt.instance;

bool _configured = false;

Future<void> configureDependencies() async {
  if (_configured) return;
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  _configured = true;
}
