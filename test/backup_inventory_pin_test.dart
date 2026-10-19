import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_inventory.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';

/// Pin test: backup's string literals must equal the REAL owner constants.
/// Tests may import across features; production backup code may not — this is
/// the loud failure a rename in any owner file triggers.
void main() {
  test('reminder key literals match notifications/reminder_settings.dart', () {
    expect(backupKeyAzkarReminderEnabled, azkarReminderEnabledKey);
    expect(backupKeyAzkarReminderTime, azkarReminderTimeKey);
    expect(backupKeyWirdReminderEnabled, wirdReminderEnabledKey);
    expect(backupKeyWirdReminderTime, wirdReminderTimeKey);
  });

  test('last-read literal matches quran/last_read_repository.dart', () {
    expect(backupKeyLastReadAyahId, lastReadAyahIdKey);
  });

  test('moshaf-row literal matches recitation/reciter_repository.dart', () {
    expect(backupKeySelectedMoshafRow, selectedMoshafKey);
  });

  test('city literal matches prayer/city_repository.dart', () {
    expect(backupKeySelectedCity, selectedCityKey);
  });

  test('tasbih literal matches tasbih/tasbih_repository.dart', () {
    expect(backupKeyTasbihState, tasbihStateKey);
  });

  test('the whitelist is exactly the six user settings keys', () {
    expect(kBackupSettingsWhitelist, {
      azkarReminderEnabledKey,
      azkarReminderTimeKey,
      wirdReminderEnabledKey,
      wirdReminderTimeKey,
      selectedCityKey,
      selectedMoshafKey,
    });
    expect(kBackupSettingsWhitelist, isNot(contains(lastReadAyahIdKey)));
    expect(kBackupSettingsWhitelist, isNot(contains(tasbihStateKey)));
  });

  test('reminder-relevant keys are the reminder keys plus the city', () {
    expect(kBackupReminderRelevantKeys, {
      azkarReminderEnabledKey,
      azkarReminderTimeKey,
      wirdReminderEnabledKey,
      wirdReminderTimeKey,
      selectedCityKey,
    });
    expect(kBackupReminderRelevantKeys, isNot(contains(selectedMoshafKey)));
  });
}
