import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the line height defaults to 2.2 and round-trips', () async {
    final db = newTestDb();
    final repo = ReaderSettingsRepository(db);

    expect(await repo.loadLineHeight(), 2.2);

    await repo.saveLineHeight(2.6);
    expect(await ReaderSettingsRepository(db).loadLineHeight(), 2.6);
  });

  test('malformed and out-of-range line heights are clamped', () async {
    final db = newTestDb();
    final repo = ReaderSettingsRepository(db);

    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: ReaderSettingsRepository.lineHeightKey,
            value: 'not-a-number',
          ),
        );
    expect(await repo.loadLineHeight(), 2.2);

    await repo.saveLineHeight(1.0);
    expect(await repo.loadLineHeight(), 1.6);

    await repo.saveLineHeight(5);
    expect(await repo.loadLineHeight(), 3.0);
  });

  test('the two reader preferences do not overwrite each other', () async {
    final db = newTestDb();
    final repo = ReaderSettingsRepository(db);

    await repo.saveFontScale(1.4);
    await repo.saveLineHeight(2.8);

    expect(await repo.loadFontScale(), 1.4);
    expect(await repo.loadLineHeight(), 2.8);
  });
}
