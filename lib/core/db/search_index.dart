import 'dart:isolate';

import '../utils/arabic_search.dart';
import 'app_database.dart';
import 'content_version.dart';

/// Row key in the settings table stamping which content version the derived
/// Quran search index was built from.
const String kSearchIndexVersionKey = 'search_index_version';

/// FTS5 virtual table DDL for Quran text search.
///
/// Uses the `trigram` tokenizer so `MATCH` preserves the existing
/// substring/contains semantics (the previous `LIKE '%token%'` behavior).
/// `rowid` carries the global ayah id (1..6236), keeping joins and ordering
/// compatible with the rest of the reader/search pipeline.
const String kAyahSearchDdl = 'CREATE VIRTUAL TABLE IF NOT EXISTS ayah_search '
    "USING fts5(text_norm, tokenize='trigram')";

/// Awaits a computation off the UI isolate.
///
/// Production passes nothing (see [ensureQuranSearchIndex] /
/// [rebuildQuranSearchIndex]) and gets [Isolate.run]; tests inject a runner to
/// pin that the normalization really leaves the UI isolate.
typedef IsolateRunner = Future<R> Function<R>(R Function() computation);

/// Builds the derived `ayah_search` index when it is missing or stale.
///
/// The index is rebuilt content, never user data: it is safe to drop and
/// recreate on any content change. Boot calls this behind the first frame;
/// a failure logs and leaves the previous index in place.
Future<void> ensureQuranSearchIndex(
  AppDatabase db, {
  IsolateRunner? run,
}) async {
  await ensureAyahSearchSchema(db);
  final stamp = await _indexStamp(db);
  if (stamp == kContentVersion && await _hasIndexedRows(db)) return;
  await rebuildQuranSearchIndex(db, run: run);
}

/// Ensures `ayah_search` exists as the current FTS5 trigram table.
///
/// Older installs may carry the legacy regular table
/// `(ayah_id INTEGER PRIMARY KEY, text_norm TEXT NOT NULL)`. That shape is
/// incompatible with FTS5 `MATCH`, so it is dropped (derived content only) and
/// recreated; the caller will then rebuild and re-stamp it.
Future<void> ensureAyahSearchSchema(AppDatabase db) async {
  final row = await db
      .customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'ayah_search'",
      )
      .getSingleOrNull();
  final sql = (row?.readNullable<String>('sql') ?? '').toUpperCase();
  if (sql.contains('USING FTS5')) return;
  if (sql.isNotEmpty) {
    // Legacy regular table (or any non-FTS5 shape): drop so the FTS5 DDL can
    // create the virtual table. Derived, rebuildable content — safe to drop.
    await db.customStatement('DROP TABLE IF EXISTS ayah_search');
  }
  await db.customStatement(kAyahSearchDdl);
}

/// Pure projection used by the worker isolate.
List<(int, String)> normalizeSearchEntries(List<(int, String)> input) => [
      for (final (id, text) in input) (id, normalizeArabic(text).toLowerCase()),
    ];

/// Builds the off-isolate job for [normalizeSearchEntries].
///
/// The closure is deliberately created here, not in the async body of
/// [rebuildQuranSearchIndex]: a closure made there captures that frame's drift
/// handle and `Isolate.run` rejects the unsendable capture ("Illegal argument in
/// isolate message").
List<(int, String)> Function() _normalizationJob(List<(int, String)> input) =>
    () => normalizeSearchEntries(input);

/// Rebuilds `ayah_search` from `ayahs.text_imlaei` in one transaction.
///
/// `text_uthmani` is private-use glyph data for the HafsSmart font, so the
/// readable imla'i text is the only searchable source. The FTS5 `rowid` is the
/// global ayah id.
Future<void> rebuildQuranSearchIndex(
  AppDatabase db, {
  IsolateRunner? run,
}) async {
  await ensureAyahSearchSchema(db);
  final rows = await db.customSelect('SELECT id, text_imlaei FROM ayahs').get();
  // Only plain records cross the isolate boundary: drift QueryRows are not a
  // stable transfer type.
  final input = [
    for (final row in rows)
      (row.read<int>('id'), row.read<String>('text_imlaei')),
  ];
  // 6,236 rows of normalization stay off the UI isolate.
  final entries = await (run ?? Isolate.run)(_normalizationJob(input));
  await db.transaction(() async {
    await db.customStatement('DELETE FROM ayah_search');
    await db.batch((batch) {
      for (final (ayahId, text) in entries) {
        batch.customStatement(
          'INSERT INTO ayah_search(rowid, text_norm) VALUES (?, ?)',
          [ayahId, text],
        );
      }
    });
    await db.customStatement(
      'INSERT OR REPLACE INTO settings_table(key, value) VALUES (?, ?)',
      [kSearchIndexVersionKey, '$kContentVersion'],
    );
  });
}

Future<int> _indexStamp(AppDatabase db) async {
  final row = await (db.select(db.settingsTable)
        ..where((s) => s.key.equals(kSearchIndexVersionKey)))
      .getSingleOrNull();
  return int.tryParse(row?.value ?? '') ?? 0;
}

Future<bool> _hasIndexedRows(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT 1 FROM ayah_search LIMIT 1')
      .getSingleOrNull();
  return row != null;
}
