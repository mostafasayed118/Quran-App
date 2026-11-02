import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';

import 'support/test_db.dart';

const String _day = '2026-11-02';

void main() {
  test('counters and favorites round-trip through the settings table',
      () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    expect((await repo.load()).remaining, isEmpty);
    expect((await repo.load()).favorites, isEmpty);

    await repo.saveRemaining('morning', const [0, 2, 3], _day);
    await repo.saveFavorites({'morning', 'evening'});

    final reloaded = await AzkarSavedStateRepository(db).load();
    expect(reloaded.day, _day);
    expect(reloaded.remaining['morning'], [0, 2, 3]);
    expect(reloaded.favorites, {'morning', 'evening'});
  });

  test('saving one collection keeps the counters of the others', () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    await repo.saveRemaining('morning', const [1, 1], _day);
    await repo.saveRemaining('evening', const [2, 0], _day);
    await repo.saveRemaining('morning', const [0, 0], _day);

    final loaded = await repo.load();
    expect(loaded.remaining['morning'], [0, 0]);
    expect(loaded.remaining['evening'], [2, 0]);
  });

  test('a write on a new day replaces the previous day counters', () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    await repo.saveRemaining('morning', const [0, 0], '2026-11-01');
    await repo.saveRemaining('evening', const [1], '2026-11-02');

    final loaded = await repo.load();
    expect(loaded.day, '2026-11-02');
    expect(loaded.remaining.keys, ['evening']);
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
    expect(loaded.day, isEmpty);
    expect(loaded.remaining, isEmpty);
    expect(loaded.favorites, isEmpty);
  });

  test('non-numeric counters and non-string ids are dropped', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.progressKey,
            value: '{"day":"$_day","counts":{"morning":[1,"x",2]}}',
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

  test('a progress row with a non-map payload is ignored, not thrown',
      () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AzkarSavedStateRepository.progressKey,
            value: '{"day":"$_day","counts":"three"}',
          ),
        );

    final loaded = await AzkarSavedStateRepository(db).load();
    expect(loaded.remaining, isEmpty);
    expect(loaded.day, isEmpty);
  });

  test('an unrelated settings row is left untouched', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: 'unrelated',
            value: 'keep-me',
          ),
        );
    final repo = AzkarSavedStateRepository(db);
    await repo.saveRemaining('morning', const [3], _day);

    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals('unrelated')))
        .getSingle();
    expect(row.value, 'keep-me');
  });
}
