import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'content_version.dart';
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
  Reciters,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @visibleForTesting
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createAll();
          }
        },
        beforeOpen: (details) async {
          // Hot-path indexes. IF NOT EXISTS: asset-seeded databases ship
          // without them, fresh databases just created their tables — one
          // idempotent statement covers every open (ayahs.surah_id is the
          // reader's per-surah query; the others are per-check lookups).
          await customStatement('CREATE INDEX IF NOT EXISTS idx_ayahs_surah '
              'ON ayahs(surah_id, number_in_surah)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_bookmarks_ayah '
              'ON bookmarks(ayah_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_downloads_lookup '
              'ON downloads(reciter_id, surah_id)');
        },
      );

  /// Dev/seed helper (tools/build_quran_db.dart): creates the full schema on
  /// a fresh executor. Wraps the protected migrator; public by design.
  Future<void> createSchemaForSeeding() => createMigrator().createAll();

  /// The bundled-content version stamped into the installed DB (0 when absent
  /// — pre-versioning installs or a fresh schema). See content_version.dart.
  Future<int> installedContentVersion() async {
    final row = await (select(settingsTable)
          ..where((s) => s.key.equals(kContentVersionKey)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }
}
