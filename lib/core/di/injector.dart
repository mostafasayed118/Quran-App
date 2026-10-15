import 'package:drift/drift.dart' show LazyDatabase;
import 'package:get_it/get_it.dart';

import '../db/app_database.dart';
import '../db/connection.dart';

final getIt = GetIt.instance;

bool _configured = false;

Future<void> configureDependencies() async {
  if (_configured) return;
  getIt.registerLazySingleton<AppDatabase>(
      () => AppDatabase(LazyDatabase(openAppDatabase)));
  _configured = true;
}
