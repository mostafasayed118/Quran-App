import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/content_version.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

import 'support/test_db.dart';

Future<void> _insertAyah(AppDatabase db, int id, String text) =>
    db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: 1,
          numberInSurah: id,
          juz: 1,
          page: 1,
          textUthmani: text,
          textImlaei: text,
        ));

void main() {
  test('builds the derived index and stamps the content version', () async {
    final db = newTestDb();
    await _insertAyah(db, 1, 'بسم الله الرحمن الرحيم');
    await _insertAyah(db, 2, 'الحمد لله رب العالمين');

    await ensureQuranSearchIndex(db);

    final count = await db
        .customSelect('SELECT COUNT(*) AS c FROM ayah_search')
        .getSingle();
    expect(count.read<int>('c'), 2);
    final stamp = await db.customSelect(
        'SELECT value FROM settings_table WHERE key = ?',
        variables: [const Variable(kSearchIndexVersionKey)]).getSingleOrNull();
    expect(stamp?.read<String>('value'), '$kContentVersion');
  });

  test('is idempotent once the stamp matches', () async {
    final db = newTestDb();
    await _insertAyah(db, 1, 'بسم الله');
    await ensureQuranSearchIndex(db);
    await ensureQuranSearchIndex(db);

    final count = await db
        .customSelect('SELECT COUNT(*) AS c FROM ayah_search')
        .getSingle();
    expect(count.read<int>('c'), 1);
  });

  test('rebuilds when content changed under an older stamp', () async {
    final db = newTestDb();
    await _insertAyah(db, 1, 'نص قديم');
    await ensureQuranSearchIndex(db);

    await (db.update(db.ayahs)..where((a) => a.id.equals(1)))
        .write(const AyahsCompanion(textImlaei: Value('نص جديد')));
    await db.customStatement(
        'DELETE FROM settings_table WHERE key = ?', [kSearchIndexVersionKey]);

    await ensureQuranSearchIndex(db);

    final row = await db
        .customSelect('SELECT text_norm FROM ayah_search WHERE ayah_id = 1')
        .getSingle();
    expect(row.read<String>('text_norm'), 'نص جديد');
  });
}
