import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/notifications/data/adhan_preferences_impl.dart';

import 'support/test_db.dart';

/// The adhan selection is a user preference, so it must survive a backup —
/// and a backup from a build that ships a reciter this one does not must still
/// restore, degrading to the default instead of failing the whole file.
BackupDocument doc({Map<String, String> settings = const {}}) => BackupDocument(
      exportedAt: DateTime(2026, 11, 4),
      schemaVersion: 2,
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
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = newTestDb();
    service = BackupService(db: db, reschedule: () async {});
  });

  Future<String?> settingValue(String key) async {
    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) =>
      db.into(db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(key: key, value: value),
          );

  test('export carries the adhan selection', () async {
    await writeSetting('adhan_id', 'omar_hisham');
    await writeSetting('adhan_fajr_id', 'khushu');

    final success = decode(await service.exportJson()) as BackupDecodeSuccess;

    expect(success.document.data.settings['adhan_id'], 'omar_hisham');
    expect(success.document.data.settings['adhan_fajr_id'], 'khushu');
  });

  test('import restores a selected adhan and a fajr override', () async {
    await service.apply(doc(settings: {
      'adhan_id': 'islam_sobhy',
      'adhan_fajr_id': 'nasser_alqatami_2',
    }));

    expect(await settingValue('adhan_id'), 'islam_sobhy');
    final prefs = AdhanPreferencesImpl(db);
    expect(await prefs.adhanId(), 'islam_sobhy');
    expect(await prefs.fajrAdhanId(), 'nasser_alqatami_2');
  });

  test('an unknown adhan id does not fail the restore', () async {
    final outcome = await service.apply(doc(settings: {
      'adhan_id': 'removed_in_a_future_build',
    }));

    // The file is accepted, not rejected: one unknown preference must never
    // cost the user their bookmarks and prayer log.
    expect(outcome, isNotNull);
    // The raw value may survive in storage; every reader normalises it.
    expect(
      await AdhanPreferencesImpl(db).adhanId(),
      kDefaultAdhanId,
    );
  });

  test('an empty fajr value restores "same as default"', () async {
    await writeSetting('adhan_fajr_id', 'khushu');

    await service.apply(doc(settings: {'adhan_fajr_id': ''}));

    expect(await AdhanPreferencesImpl(db).fajrAdhanId(), isNull);
  });
}
