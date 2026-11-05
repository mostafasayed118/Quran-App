import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';
import 'package:quran_yahdi/features/backup/data/backup_inventory.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_offset_repository.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta_repository.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';
import 'package:quran_yahdi/features/ramadan/data/qada_repository.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';

/// Pin test (Class B, see `docs/decisions/2026-11-02-frozen-test-policy.md`):
/// backup's string literals must equal the REAL owner constants.
///
/// Tests may import across features; production backup code may not — this is
/// the loud failure a rename in any owner file triggers.
void main() {
  test('reminder key literals match notifications/reminder_settings.dart', () {
    expect(backupKeyAzkarReminderEnabled, azkarReminderEnabledKey);
    expect(backupKeyAzkarReminderTime, azkarReminderTimeKey);
    expect(backupKeyWirdReminderEnabled, wirdReminderEnabledKey);
    expect(backupKeyWirdReminderTime, wirdReminderTimeKey);
    expect(backupKeyPrayerReminderEnabled, prayerReminderEnabledKey);
  });

  test('prayer config literals match core/domain/prayer_config.dart', () {
    expect(backupKeyPrayerCalcMethod, PrayerConfig.methodKey);
    expect(backupKeyPrayerMadhab, PrayerConfig.madhabKey);
    expect(backupKeyPrayerEnabledPrayers, PrayerConfig.enabledPrayersKey);
    expect(backupKeyPrayerPreAdhanMinutes, PrayerConfig.preAdhanMinutesKey);
    expect(backupKeyPrayerAdjustments, PrayerConfig.adjustmentsKey);
    expect(backupKeyPrayerHighLatitude, PrayerConfig.highLatitudeKey);
  });

  test('reader and azkar literals match their repositories', () {
    expect(backupKeyReaderFontScale, ReaderSettingsRepository.fontScaleKey);
    expect(backupKeyReaderLineHeight, ReaderSettingsRepository.lineHeightKey);
    expect(backupKeyHijriDayOffset, HijriOffsetRepository.key);
    expect(backupKeyBookmarkMeta, BookmarkMetaRepository.key);
    expect(backupKeyQadaMissedFasts, QadaRepository.key);
    expect(
      backupKeyAzkarProgress,
      AzkarSavedStateRepository.progressKey,
    );
    expect(
      backupKeyAzkarFavorites,
      AzkarSavedStateRepository.favoritesKey,
    );
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

  test('adhan literals match core/domain/adhan_preferences.dart', () {
    expect(backupKeyAdhanId, adhanIdKey);
    expect(backupKeyAdhanFajrId, adhanFajrIdKey);
  });

  test('the whitelist is exactly the declared user settings keys', () {
    expect(kBackupSettingsWhitelist, {
      azkarReminderEnabledKey,
      azkarReminderTimeKey,
      wirdReminderEnabledKey,
      wirdReminderTimeKey,
      prayerReminderEnabledKey,
      PrayerConfig.methodKey,
      PrayerConfig.madhabKey,
      PrayerConfig.enabledPrayersKey,
      PrayerConfig.preAdhanMinutesKey,
      PrayerConfig.adjustmentsKey,
      PrayerConfig.highLatitudeKey,
      ReaderSettingsRepository.fontScaleKey,
      ReaderSettingsRepository.lineHeightKey,
      HijriOffsetRepository.key,
      BookmarkMetaRepository.key,
      QadaRepository.key,
      AzkarSavedStateRepository.progressKey,
      AzkarSavedStateRepository.favoritesKey,
      selectedCityKey,
      selectedMoshafKey,
      adhanIdKey,
      adhanFajrIdKey,
    });
    // Entities and app-managed keys never ride the settings whitelist.
    expect(kBackupSettingsWhitelist, isNot(contains(lastReadAyahIdKey)));
    expect(kBackupSettingsWhitelist, isNot(contains(tasbihStateKey)));
  });

  test('reminder-relevant keys are the reminder inputs plus the city', () {
    expect(kBackupReminderRelevantKeys, {
      azkarReminderEnabledKey,
      azkarReminderTimeKey,
      wirdReminderEnabledKey,
      wirdReminderTimeKey,
      prayerReminderEnabledKey,
      PrayerConfig.methodKey,
      PrayerConfig.madhabKey,
      PrayerConfig.enabledPrayersKey,
      PrayerConfig.preAdhanMinutesKey,
      PrayerConfig.adjustmentsKey,
      PrayerConfig.highLatitudeKey,
      selectedCityKey,
      adhanIdKey,
      adhanFajrIdKey,
    });
    // Not planner inputs: the reader's font scale and the azkar counters.
    expect(kBackupReminderRelevantKeys,
        isNot(contains(ReaderSettingsRepository.fontScaleKey)));
    expect(kBackupReminderRelevantKeys,
        isNot(contains(AzkarSavedStateRepository.progressKey)));
    expect(kBackupReminderRelevantKeys, isNot(contains(selectedMoshafKey)));
  });
}
