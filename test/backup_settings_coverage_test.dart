import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';
import 'package:quran_yahdi/features/backup/data/backup_inventory.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';

/// Inventory pin (Class B): **every user preference the app persists must be
/// exportable**.
///
/// This is the guard against the bug class that shipped in the wave-A window:
/// a new settings key landed in a repository and silently stayed out of the
/// backup whitelist, so an export/import reset it. Adding a preference means
/// adding it here *and* to `kBackupSettingsWhitelist` in the same commit.
void main() {
  /// Keys that represent a user choice and must survive export → import.
  const userPreferenceKeys = <String>{
    // Reminders (notifications/reminder_settings.dart).
    azkarReminderEnabledKey,
    azkarReminderTimeKey,
    wirdReminderEnabledKey,
    wirdReminderTimeKey,
    prayerReminderEnabledKey,
    // Prayer configuration (core/domain/prayer_config.dart).
    PrayerConfig.methodKey,
    PrayerConfig.madhabKey,
    PrayerConfig.enabledPrayersKey,
    PrayerConfig.preAdhanMinutesKey,
    // Reader display (quran/reader_settings_repository.dart).
    ReaderSettingsRepository.fontScaleKey,
    // Azkar session state (azkar/azkar_saved_state_repository.dart).
    AzkarSavedStateRepository.progressKey,
    AzkarSavedStateRepository.favoritesKey,
    // Prayer location + reciter (prayer/city_repository.dart,
    // recitation/reciter_repository.dart).
    selectedCityKey,
    selectedMoshafKey,
  };

  test('every user preference key is in the backup whitelist', () {
    final missing =
        userPreferenceKeys.difference(kBackupSettingsWhitelist).toList();
    expect(
      missing,
      isEmpty,
      reason: 'these preference keys would be lost on export/import: $missing',
    );
  });

  test('the whitelist holds only user preferences', () {
    expect(kBackupSettingsWhitelist, userPreferenceKeys);
  });

  test('entities and app-managed keys stay out of the whitelist', () {
    // The last-read pointer and tasbih travel as their own typed entities.
    expect(kBackupSettingsWhitelist, isNot(contains(lastReadAyahIdKey)));
    expect(kBackupSettingsWhitelist, isNot(contains(tasbihStateKey)));
  });

  test('every reminder input is reminder-relevant', () {
    const reminderInputs = <String>{
      azkarReminderEnabledKey,
      azkarReminderTimeKey,
      wirdReminderEnabledKey,
      wirdReminderTimeKey,
      prayerReminderEnabledKey,
      PrayerConfig.methodKey,
      PrayerConfig.madhabKey,
      PrayerConfig.enabledPrayersKey,
      PrayerConfig.preAdhanMinutesKey,
      selectedCityKey,
    };
    expect(kBackupReminderRelevantKeys, reminderInputs);
  });

  test('display-only and session-only keys never trigger a re-plan', () {
    for (final key in const [
      ReaderSettingsRepository.fontScaleKey,
      AzkarSavedStateRepository.progressKey,
      AzkarSavedStateRepository.favoritesKey,
      selectedMoshafKey,
    ]) {
      expect(kBackupReminderRelevantKeys, isNot(contains(key)));
    }
  });
}
