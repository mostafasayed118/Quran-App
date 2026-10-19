/// Cross-feature settings keys used by backup.
///
/// These are STRING LITERALS on purpose: production backup code must not
/// import other features (the architecture guard scans `lib/features/**`).
/// `test/backup_inventory_pin_test.dart` imports the REAL owner constants and
/// asserts literal == constant, so a rename in any owner file fails loudly.
library;

/// `lib/features/notifications/data/reminder_settings.dart`.
const String backupKeyAzkarReminderEnabled = 'azkar_reminder_enabled';
const String backupKeyAzkarReminderTime = 'azkar_reminder_time';
const String backupKeyWirdReminderEnabled = 'wird_reminder_enabled';
const String backupKeyWirdReminderTime = 'wird_reminder_time';

/// `lib/features/prayer/data/city_repository.dart`.
const String backupKeySelectedCity = 'selected_city';

/// `lib/features/quran/data/last_read_repository.dart`.
const String backupKeyLastReadAyahId = 'last_read_ayah_id';

/// `lib/features/recitation/data/reciter_repository.dart`.
const String backupKeySelectedMoshafRow = 'selected_moshaf_row';

/// `lib/features/tasbih/data/tasbih_repository.dart`.
const String backupKeyTasbihState = 'tasbih_state';

/// The settings keys a restore may import (import wins, key-by-key).
/// The last-read pointer and tasbih state travel as their own typed entities
/// and are deliberately NOT part of this map; app-managed keys such as
/// `content_version` are deliberately excluded.
const Set<String> kBackupSettingsWhitelist = {
  backupKeyAzkarReminderEnabled,
  backupKeyAzkarReminderTime,
  backupKeyWirdReminderEnabled,
  backupKeyWirdReminderTime,
  backupKeySelectedCity,
  backupKeySelectedMoshafRow,
};

/// Keys whose change needs a reminder re-plan after apply — mirrors the boot
/// scheduler inputs (city + azkar/wird settings; see `scheduleReminders`).
const Set<String> kBackupReminderRelevantKeys = {
  backupKeyAzkarReminderEnabled,
  backupKeyAzkarReminderTime,
  backupKeyWirdReminderEnabled,
  backupKeyWirdReminderTime,
  backupKeySelectedCity,
};
