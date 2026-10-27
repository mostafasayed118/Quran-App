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
  HadithEntries,
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
          // The khatma page query filters `ayahs.page`; without this index
          // every call scans the whole 6236-row table.
          await customStatement('CREATE INDEX IF NOT EXISTS idx_ayahs_page '
              'ON ayahs(page)');
          // One bookmark per ayah is a user-visible invariant. Repair any
          // duplicates left by the old read-then-write toggle before the
          // unique index is created (a failed CREATE would abort every open).
          await customStatement('DELETE FROM bookmarks WHERE id NOT IN '
              '(SELECT MIN(id) FROM bookmarks GROUP BY ayah_id)');
          await customStatement('DROP INDEX IF EXISTS idx_bookmarks_ayah');
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_bookmarks_ayah '
              'ON bookmarks(ayah_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_downloads_lookup '
              'ON downloads(reciter_id, surah_id)');
          // The downloads screen filters `status='done'`; without this index
          // every open of that screen scans the whole downloads table.
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_downloads_status '
              'ON downloads(status)');
          // Derived Quran search index (see core/db/search_index.dart). A raw
          // table on purpose: it is rebuilt content, not a drift entity, and
          // keeping it out of the drift schema leaves the migration contract
          // untouched.
          await customStatement('CREATE TABLE IF NOT EXISTS ayah_search '
              '(ayah_id INTEGER PRIMARY KEY, text_norm TEXT NOT NULL)');
          // Hadith pack read index. Already in the drift schema for fresh
          // databases; this idempotent statement upgrades an existing v2 file
          // without changing the pinned user_version.
          await customStatement('CREATE TABLE IF NOT EXISTS hadith_entries '
              '(pack_id TEXT NOT NULL, ordinal INTEGER NOT NULL, '
              'number INTEGER NOT NULL, body TEXT NOT NULL, '
              'PRIMARY KEY (pack_id, ordinal))');
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
