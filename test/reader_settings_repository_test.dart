import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the reader font scale defaults to 1 and round-trips', () async {
    final db = newTestDb();
    final repo = ReaderSettingsRepository(db);

    expect(await repo.loadFontScale(), 1);

    await repo.saveFontScale(1.5);
    expect(await ReaderSettingsRepository(db).loadFontScale(), 1.5);
  });

  test('malformed and out-of-range values are clamped', () async {
    final db = newTestDb();
    final repo = ReaderSettingsRepository(db);

    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: ReaderSettingsRepository.fontScaleKey,
            value: 'not-a-number',
          ),
        );
    expect(await repo.loadFontScale(), 1);

    await repo.saveFontScale(0.2);
    expect(await repo.loadFontScale(), 0.8);

    await repo.saveFontScale(3);
    expect(await repo.loadFontScale(), 2);
  });
}
