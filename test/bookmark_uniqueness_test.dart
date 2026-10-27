import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the schema rejects a duplicate bookmark for the same ayah', () async {
    final db = newTestDb();
    addTearDown(db.close);

    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8));
    await expectLater(
      db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8)),
      throwsA(anything),
    );
  });

  test('concurrent toggles never leave two rows for one ayah', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final repo = AyahRepository(db);

    await Future.wait([repo.toggleBookmark(8), repo.toggleBookmark(8)]);

    final rows = await db.select(db.bookmarks).get();
    expect(rows.length, lessThanOrEqualTo(1));
  });
}
