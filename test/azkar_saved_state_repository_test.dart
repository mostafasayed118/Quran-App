import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';

import 'support/test_db.dart';

void main() {
  test('counters and favorites round-trip through the settings table',
      () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    expect((await repo.load()).remaining, isEmpty);
    expect((await repo.load()).favorites, isEmpty);

    await repo.saveRemaining('morning', const [0, 2, 3]);
    await repo.saveFavorites({'morning', 'evening'});

    final reloaded = await AzkarSavedStateRepository(db).load();
    expect(reloaded.remaining['morning'], [0, 2, 3]);
    expect(reloaded.favorites, {'morning', 'evening'});
  });

  test('saving one collection keeps the counters of the others', () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    await repo.saveRemaining('morning', const [1, 1]);
    await repo.saveRemaining('evening', const [2, 0]);
    await repo.saveRemaining('morning', const [0, 0]);

    final loaded = await repo.load();
    expect(loaded.remaining['morning'], [0, 0]);
    expect(loaded.remaining['evening'], [2, 0]);
  });

  test('malformed rows degrade to an empty state', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.progressKey,
            value: 'not-json',
          ),
        );
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.favoritesKey,
            value: '{"not":"a list"}',
          ),
        );
    final repo = AzkarSavedStateRepository(db);

    final loaded = await repo.load();
    expect(loaded.remaining, isEmpty);
    expect(loaded.favorites, isEmpty);
  });

  test('non-numeric counters and non-string ids are dropped', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.progressKey,
            value: '{"morning":[1,"x",2]}',
          ),
        );
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.favoritesKey,
            value: '["morning",5,""]',
          ),
        );
    final repo = AzkarSavedStateRepository(db);

    final loaded = await repo.load();
    expect(loaded.remaining['morning'], [1, 2]);
    expect(loaded.favorites, {'morning'});
  });

  test('a progress row with a non-list value is ignored, not thrown', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.progressKey,
            value: '{"morning":"three"}',
          ),
        );

    expect((await AzkarSavedStateRepository(db).load()).remaining, isEmpty);
  });

  test('values survive a schema-typed settings write', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: 'unrelated',
            value: 'keep-me',
          ),
        );
    final repo = AzkarSavedStateRepository(db);
    await repo.saveRemaining('morning', const [3]);

    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals('unrelated')))
        .getSingle();
    expect(row.value, 'keep-me');
  });
}
