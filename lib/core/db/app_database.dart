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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createAll();
          }
          if (from < 3) {
            // v3 records the derived-schema contract (and is the baseline for
            // the drift snapshot). The full-table scans stop because of the
            // index guards inside the shared function, not because of this
            // call; this is a safety net for a file that lost an object before
            // the bump.
            await _ensureDerivedSchema();
          }
        },
        beforeOpen: (details) async {
          // Non-destructive, O(1) on a healthy file: the bundled asset DB ships
          // without these raw objects, so every open reconciles them. The
          // repair only runs when a unique index is actually missing.
          await _ensureDerivedSchema();
        },
      );

  /// Raw objects the drift schema cannot express, plus the repair that has to
  /// run before each unique index exists.
  ///
  /// Everything here is idempotent: the index guards are a single
  /// `sqlite_master` lookup each, and the table/index creates use IF NOT
  /// EXISTS.
  Future<void> _ensureDerivedSchema() async {
    // Hot-path indexes (ayahs.surah_id is the reader's per-surah query).
    await customStatement('CREATE INDEX IF NOT EXISTS idx_ayahs_surah '
        'ON ayahs(surah_id, number_in_surah)');
    // The khatma page query filters `ayahs.page`; without this index every
    // call scans the whole 6236-row table.
    await customStatement('CREATE INDEX IF NOT EXISTS idx_ayahs_page '
        'ON ayahs(page)');
    // One bookmark per ayah is a user-visible invariant. When the unique index
    // is missing, repair duplicates left by the old read-then-write toggle
    // before creating it (a failed CREATE would abort every open). A legacy
    // NON-unique index under the same name is dropped first: `CREATE UNIQUE`
    // fails while the name is taken, and this runs in beforeOpen.
    if (!await _uniqueIndexExists('idx_bookmarks_ayah')) {
      await customStatement('DROP INDEX IF EXISTS idx_bookmarks_ayah');
      await customStatement('DELETE FROM bookmarks WHERE id NOT IN '
          '(SELECT MIN(id) FROM bookmarks GROUP BY ayah_id)');
      await customStatement('CREATE UNIQUE INDEX idx_bookmarks_ayah '
          'ON bookmarks(ayah_id)');
    }
    // One download per (reciter, surah) is a user-visible invariant: the row
    // is the registry entry of exactly one audio file, and every read of it
    // uses getSingleOrNull(). The oldest row wins (it owns the file).
    if (!await _uniqueIndexExists('idx_downloads_lookup')) {
      await customStatement('DROP INDEX IF EXISTS idx_downloads_lookup');
      await customStatement('DELETE FROM downloads WHERE id NOT IN '
          '(SELECT MIN(id) FROM downloads GROUP BY reciter_id, surah_id)');
      await customStatement('CREATE UNIQUE INDEX idx_downloads_lookup '
          'ON downloads(reciter_id, surah_id)');
    }
    // The downloads screen filters `status='done'`.
    await customStatement('CREATE INDEX IF NOT EXISTS idx_downloads_status '
        'ON downloads(status)');
    // Derived Quran search index (see core/db/search_index.dart). A raw table
    // on purpose: it is rebuilt content, not a drift entity, and keeping it out
    // of the drift schema leaves the migration contract untouched.
    await customStatement('CREATE TABLE IF NOT EXISTS ayah_search '
        '(ayah_id INTEGER PRIMARY KEY, text_norm TEXT NOT NULL)');
    // Hadith pack read index (in the drift schema for fresh databases).
    await customStatement('CREATE TABLE IF NOT EXISTS hadith_entries '
        '(pack_id TEXT NOT NULL, ordinal INTEGER NOT NULL, '
        'number INTEGER NOT NULL, body TEXT NOT NULL, '
        'PRIMARY KEY (pack_id, ordinal))');
  }

  /// Whether [name] is an index whose SQL says UNIQUE.
  ///
  /// A non-unique index with the same name (written by an older build) must be
  /// replaced, not trusted — otherwise the repair would be skipped and the
  /// invariant would silently stay unenforced.
  Future<bool> _uniqueIndexExists(String name) async {
    final row = await customSelect(
      "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = ?",
      variables: [Variable.withString(name)],
    ).getSingleOrNull();
    final sql = row?.readNullable<String>('sql') ?? '';
    return sql.toUpperCase().contains('UNIQUE');
  }

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
