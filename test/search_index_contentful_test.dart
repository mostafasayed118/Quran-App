import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

import 'support/test_db.dart';

/// Pins the invariant that makes short-token search possible.
///
/// The trigram tokenizer cannot represent a token shorter than three
/// characters, so `QuranSearchRepository` falls back to a `text_norm LIKE ?`
/// scan for those queries. That fallback only works while the FTS5 table is
/// **contentful**: a contentless table (`content=''`) stores no column values,
/// so `SELECT text_norm` returns NULL and the LIKE matches nothing — which
/// would silently restore the exact bug the fallback exists to fix.
///
/// Measured on the 6,236-ayah corpus, contentless would save ~815 KB. That is a
/// deliberate trade, not an oversight, and this test is the tripwire: if
/// someone flips the tokenizer to contentless to reclaim the size, this fails
/// with the reason instead of shipping a silently empty search.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          revelationType: 'makkah',
          ayahCount: 1,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'بسم الله الرحمن الرحيم',
          textImlaei: 'بسم الله الرحمن الرحيم',
        ));
    await rebuildQuranSearchIndex(db);
  });

  test('the DDL is not contentless', () {
    expect(kAyahSearchDdl.contains("content=''"), isFalse,
        reason: 'a contentless FTS5 table cannot serve the short-token LIKE '
            'fallback; reclaiming the ~815 KB needs a real ayahs column, not '
            'a tokenizer flag');
  });

  test('text_norm is readable, so the short-token scan can match', () async {
    final rows = await db
        .customSelect('SELECT text_norm FROM ayah_search LIMIT 5')
        .get();
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.readNullable<String>('text_norm'), isNotNull,
          reason: 'NULL here means the table went contentless');
    }

    // The exact predicate the repository runs for a 2-char token.
    final hits = await db.customSelect(
      'SELECT COUNT(*) AS c FROM ayah_search s WHERE s.text_norm LIKE ?',
      variables: const [Variable<String>('%ال%')],
    ).getSingle();
    expect(hits.read<int>('c'), greaterThan(0),
        reason: '«ال» is in the seeded ayah; the LIKE must see the text');
  });
}
