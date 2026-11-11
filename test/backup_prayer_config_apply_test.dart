import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_inventory.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';

import 'support/test_db.dart';

BackupDocument _document(Map<String, String> settings) => BackupDocument(
      exportedAt: DateTime(2026, 11, 2),
      schemaVersion: 1,
      data: BackupData(
        bookmarks: const [],
        lastReadAyahId: null,
        khatma: const [],
        prayerLog: const [],
        tasbih: null,
        settings: settings,
      ),
    );

void main() {
  test('an imported prayer configuration is written and triggers a re-plan',
      () async {
    final db = newTestDb();
    var reschedules = 0;
    final service = BackupService(
      db: db,
      reschedule: () async => reschedules++,
    );

    final outcome = await service.apply(_document({
      PrayerConfig.methodKey: 'ummAlQura',
      PrayerConfig.madhabKey: 'hanafi',
      PrayerConfig.enabledPrayersKey: 'fajr,dhuhr',
      PrayerConfig.preAdhanMinutesKey: '10',
    }));

    final rows = await (db.select(db.settingsTable)
          ..where((s) => s.key.isIn([
                PrayerConfig.methodKey,
                PrayerConfig.madhabKey,
                PrayerConfig.enabledPrayersKey,
                PrayerConfig.preAdhanMinutesKey,
              ])))
        .get();
    final values = {for (final row in rows) row.key: row.value};

    expect(values[PrayerConfig.methodKey], 'ummAlQura');
    expect(values[PrayerConfig.madhabKey], 'hanafi');
    expect(values[PrayerConfig.enabledPrayersKey], 'fajr,dhuhr');
    expect(values[PrayerConfig.preAdhanMinutesKey], '10');
    expect(outcome.rescheduled, isTrue);
    expect(reschedules, 1);
  });

  test('a failed reminder re-plan does not turn the import into a failure',
      () async {
    final db = newTestDb();
    final service = BackupService(
      db: db,
      reschedule: () async => throw StateError('schedule down'),
    );

    final outcome = await service.apply(_document({
      PrayerConfig.methodKey: 'ummAlQura',
      PrayerConfig.madhabKey: 'hanafi',
      PrayerConfig.enabledPrayersKey: 'fajr,dhuhr',
      PrayerConfig.preAdhanMinutesKey: '10',
    }));

    expect(outcome.rescheduleFailed, isTrue);
    expect(outcome.rescheduled, isTrue);
    expect(outcome.summary.settingsKeysApplied, 4);

    final row = await (db.select(db.settingsTable)
          ..where((setting) => setting.key.equals(PrayerConfig.methodKey)))
        .getSingle();
    expect(row.value, 'ummAlQura',
        reason: 'the transaction committed before the hook ran');
  });

  test('an imported font scale and azkar state are written without a re-plan',
      () async {
    final db = newTestDb();
    var reschedules = 0;
    final service = BackupService(
      db: db,
      reschedule: () async => reschedules++,
    );

    final outcome = await service.apply(_document({
      ReaderSettingsRepository.fontScaleKey: '1.4',
      backupKeyAzkarProgress: '{"day":"2026-11-02","counts":{}}',
    }));

    expect(outcome.rescheduled, isFalse);
    expect(reschedules, 0);
    expect(outcome.summary.settingsKeysApplied, 2);
    expect(await ReaderSettingsRepository(db).loadFontScale(), 1.4);
  });

  test('a key outside the whitelist is ignored, never written', () async {
    final db = newTestDb();
    var reschedules = 0;
    final service = BackupService(
      db: db,
      reschedule: () async => reschedules++,
    );

    await service.apply(_document({
      'content_version': '999',
      backupKeyLastReadAyahId: '42',
    }));

    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals('content_version')))
        .getSingleOrNull();
    expect(row, isNull);
    expect(reschedules, 0);
  });
}
