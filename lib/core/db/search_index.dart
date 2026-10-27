import 'dart:isolate';

import '../utils/arabic_search.dart';
import 'app_database.dart';
import 'content_version.dart';

/// Row key in the settings table stamping which content version the derived
/// Quran search index was built from.
const String kSearchIndexVersionKey = 'search_index_version';

/// Builds the derived `ayah_search` index when it is missing or stale.
///
/// The index is rebuilt content, never user data: it is safe to drop and
/// recreate on any content change. Boot calls this behind the first frame;
/// a failure logs and leaves the previous index in place.
Future<void> ensureQuranSearchIndex(AppDatabase db) async {
  final stamp = await _indexStamp(db);
  if (stamp == kContentVersion && await _hasIndexedRows(db)) return;
  await rebuildQuranSearchIndex(db);
}

/// Pure projection used by the worker isolate.
List<(int, String)> normalizeSearchEntries(List<(int, String)> input) => [
      for (final (id, text) in input) (id, normalizeArabic(text).toLowerCase()),
    ];

Future<List<(int, String)>> _normalizeEntriesInIsolate(
  List<(int, String)> input,
) =>
    Isolate.run(() => normalizeSearchEntries(input));

/// Rebuilds `ayah_search` from `ayahs.text_imlaei` in one transaction.
///
/// `text_uthmani` is private-use glyph data for the HafsSmart font, so the
/// readable imla'i text is the only searchable source.
Future<void> rebuildQuranSearchIndex(AppDatabase db) async {
  final rows = await db.customSelect('SELECT id, text_imlaei FROM ayahs').get();
  // Only plain records cross the isolate boundary: drift QueryRows are not a
  // stable transfer type.
  final input = [
    for (final row in rows)
      (row.read<int>('id'), row.read<String>('text_imlaei')),
  ];
  final entries = await _normalizeEntriesInIsolate(input);
  await db.transaction(() async {
    await db.customStatement('DELETE FROM ayah_search');
    await db.batch((batch) {
      for (final (ayahId, text) in entries) {
        batch.customStatement(
          'INSERT OR REPLACE INTO ayah_search(ayah_id, text_norm) '
          'VALUES (?, ?)',
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
