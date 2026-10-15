import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Surahs,
  Ayahs,
  Bookmarks,
  KhatmaProgress,
  PrayerLog,
  InstalledPacks,
  Downloads,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @visibleForTesting
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() => LazyDatabase(() => openAppDatabase());
}
