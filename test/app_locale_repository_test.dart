import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/features/settings/data/app_locale_repository.dart';

import 'support/test_db.dart';

void main() {
  test('a fresh install is Arabic', () async {
    final db = newTestDb();

    expect(await AppLocaleRepository(db).load(), AppLanguage.arabic);
  });

  test('a saved language survives a new repository instance', () async {
    final db = newTestDb();
    final repo = AppLocaleRepository(db);

    await repo.save(AppLanguage.english);

    expect(await repo.load(), AppLanguage.english);
    expect(await AppLocaleRepository(db).load(), AppLanguage.english);
  });

  test('a malformed stored value falls back to Arabic', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: AppLocaleRepository.key,
            value: 'fr',
          ),
        );

    expect(await AppLocaleRepository(db).load(), AppLanguage.arabic);
  });

  test('an unrelated settings row is untouched', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: 'unrelated', value: 'keep-me'),
        );

    await AppLocaleRepository(db).save(AppLanguage.english);

    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals('unrelated')))
        .getSingle();
    expect(row.value, 'keep-me');
  });

  test('unknown codes resolve to Arabic, known ones to themselves', () {
    expect(AppLanguage.fromCode(null), AppLanguage.arabic);
    expect(AppLanguage.fromCode(''), AppLanguage.arabic);
    expect(AppLanguage.fromCode('ar'), AppLanguage.arabic);
    expect(AppLanguage.fromCode('en'), AppLanguage.english);
  });
}
