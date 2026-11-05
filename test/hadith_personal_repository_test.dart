import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/hadith_bookmark_repository.dart';
import 'package:quran_yahdi/features/library/data/hadith_position_repository.dart';

import 'support/test_db.dart';

void main() {
  test('bookmarks round-trip per pack and are removed when empty', () async {
    final db = newTestDb();
    final repo = HadithBookmarkRepository(db);

    expect(await repo.load('p1'), isEmpty);

    await repo.save('p1', {3, 1});
    await repo.save('p2', {7});

    expect(await HadithBookmarkRepository(db).load('p1'), {1, 3});
    expect(await HadithBookmarkRepository(db).load('p2'), {7});

    await repo.save('p1', {});
    expect(await repo.load('p1'), isEmpty);
    expect(await repo.load('p2'), {7});
  });

  test('a malformed bookmark row degrades to empty', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: HadithBookmarkRepository.key,
            value: 'not-json',
          ),
        );

    expect(await HadithBookmarkRepository(db).load('p1'), isEmpty);
  });

  test('positions round-trip per pack and zero clears the entry', () async {
    final db = newTestDb();
    final repo = HadithPositionRepository(db);

    expect(await repo.load('p1'), 0);

    await repo.save('p1', 20);
    await repo.save('p2', 5);

    expect(await HadithPositionRepository(db).load('p1'), 20);
    expect(await HadithPositionRepository(db).load('p2'), 5);

    await repo.save('p1', 0);
    expect(await repo.load('p1'), 0);
    expect(await repo.load('p2'), 5);
  });

  test('a malformed position row degrades to zero', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: HadithPositionRepository.key,
            value: '{"p1": -4, "p2": "x"}',
          ),
        );

    expect(await HadithPositionRepository(db).load('p1'), 0);
    expect(await HadithPositionRepository(db).load('p2'), 0);
  });
}
