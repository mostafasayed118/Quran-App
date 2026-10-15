import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

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
  AppDatabase(super.executor);

  @visibleForTesting
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 1;

  /// Dev/seed helper (tools/build_quran_db.dart): creates the full schema on
  /// a fresh executor. Wraps the protected migrator; public by design.
  Future<void> createSchemaForSeeding() => createMigrator().createAll();
}
