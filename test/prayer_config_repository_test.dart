import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_config_repository.dart';

import 'support/test_db.dart';

void main() {
  test('missing rows load the historical defaults', () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);

    expect(repo.current, PrayerConfig.egyptian);
    expect(await repo.load(), PrayerConfig.egyptian);
    expect(repo.current, PrayerConfig.egyptian);
  });

  test('save persists both keys and updates current', () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);
    const config = PrayerConfig(
      method: PrayerCalculationMethod.ummAlQura,
      madhab: PrayerMadhab.hanafi,
    );

    await repo.save(config);

    expect(repo.current, config);
    final reloaded = PrayerConfigRepository(db);
    expect(await reloaded.load(), config);
  });

  test('malformed stored values degrade to the defaults', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: PrayerConfig.methodKey,
            value: 'not-a-method',
          ),
        );
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: PrayerConfig.madhabKey,
            value: 'not-a-madhab',
          ),
        );
    final repo = PrayerConfigRepository(db);

    expect(await repo.load(), PrayerConfig.egyptian);
    expect(repo.current, PrayerConfig.egyptian);
  });

  test('changes emits after a successful save', () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);
    final next = repo.changes.first;
    const config = PrayerConfig(method: PrayerCalculationMethod.karachi);

    await repo.save(config);

    expect(await next, config);
  });
}
