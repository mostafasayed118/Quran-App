import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_config_repository.dart';

import 'support/test_db.dart';

void main() {
  test('missing rows load the historical defaults', () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);

    expect(repo.current, PrayerConfig.egyptian);
    expect(repo.current.enabledPrayers, PrayerConfig.defaultEnabledPrayers);
    expect(repo.current.preAdhanMinutes, 0);
    expect(await repo.load(), PrayerConfig.egyptian);
    expect(repo.current, PrayerConfig.egyptian);
  });

  test('save persists both keys and updates current', () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);
    const config = PrayerConfig(
      method: PrayerCalculationMethod.ummAlQura,
      madhab: PrayerMadhab.hanafi,
      enabledPrayers: {PrayerName.fajr, PrayerName.isha},
      preAdhanMinutes: 15,
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
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: PrayerConfig.enabledPrayersKey,
            value: 'sunrise,unknown',
          ),
        );
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: PrayerConfig.preAdhanMinutesKey,
            value: '999',
          ),
        );
    final repo = PrayerConfigRepository(db);

    final loaded = await repo.load();
    expect(loaded.method, PrayerCalculationMethod.egyptian);
    expect(loaded.madhab, PrayerMadhab.shafi);
    expect(loaded.enabledPrayers, isEmpty);
    expect(loaded.preAdhanMinutes, 60);
  });

  test('negative pre-adhan minutes clamp to zero', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: PrayerConfig.preAdhanMinutesKey,
            value: '-5',
          ),
        );
    final repo = PrayerConfigRepository(db);

    expect((await repo.load()).preAdhanMinutes, 0);
  });

  test('adjustments and the high-latitude rule round-trip through the table',
      () async {
    final db = newTestDb();
    final repo = PrayerConfigRepository(db);
    const config = PrayerConfig(
      adjustments: {PrayerName.fajr: 6, PrayerName.isha: -2},
      highLatitude: PrayerHighLatitudeRule.twilightAngle,
    );

    await repo.save(config);

    final reloaded = PrayerConfigRepository(db);
    expect(await reloaded.load(), config);
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
