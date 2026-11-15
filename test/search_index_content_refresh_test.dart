import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/content_version.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

import 'support/test_db.dart';

AyahsCompanion _ayah(int id, String text) => AyahsCompanion.insert(
      id: Value(id),
      surahId: 1,
      numberInSurah: id,
      juz: 1,
      page: 1,
      textUthmani: text,
      textImlaei: text,
    );

Future<void> _setInstalledVersion(AppDatabase db, int version) =>
    db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: kContentVersionKey,
            value: '$version',
          ),
        );

void main() {
  test('a completed content refresh rebuilds an index built from older content',
      () async {
    final db = newTestDb();
    await db.into(db.ayahs).insert(_ayah(1, 'النص القديم'));
    await _setInstalledVersion(db, 1);
    await ensureQuranSearchIndex(db);

    // The first boot after the update failed to refresh the content, so the
    // index was built from v1 while the app constant already said v2. A later
    // boot completes the refresh: the ayah text changes to v2.
    await (db.update(db.ayahs)..where((a) => a.id.equals(1))).write(
      AyahsCompanion(textImlaei: Value('النص الجديد')),
    );
    await _setInstalledVersion(db, 2);

    await ensureQuranSearchIndex(db);

    final row = await db
        .customSelect('SELECT text_norm FROM ayah_search WHERE rowid = 1')
        .getSingle();
    expect(row.read<String>('text_norm'), contains('الجديد'),
        reason: 'the stamp must follow the installed content version; with the '
            'app constant it stays "current" and the index is never rebuilt');
  });
}
