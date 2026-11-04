/// Cross-feature settings keys used by backup.
///
/// These are STRING LITERALS on purpose: production backup code must not
/// import other features (the architecture guard scans `lib/features/**`).
/// `test/backup_inventory_pin_test.dart` imports the REAL owner constants and
/// asserts literal == constant, so a rename in any owner file fails loudly.
library;

import 'dart:convert';

/// The selected city as it may leave the app: the id and the names, NEVER the
/// coordinates.
///
/// The privacy policy says the location is never stored or shared with any
/// party, and a backup file is a file the user hands to somebody else - so
/// the GPS point must not travel with it. The id survives, which is what an
/// import needs to restore the selection (the prayer feature resolves the id
/// against its own offline city catalog).
///
/// Returns null when the value is not a city object: an unreadable value is
/// never exported, and a value that carries no id cannot be restored.
String? redactedSelectedCity(String? value) {
  if (value == null || value.isEmpty) return null;
  Map<String, dynamic> city;
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) return null;
    city = decoded;
  } on Object {
    return null;
  }
  final id = city['id'];
  if (id is! String || id.isEmpty) return null;
  final nameAr = city['nameAr'];
  final nameEn = city['nameEn'];
  return jsonEncode(<String, dynamic>{
    'id': id,
    if (nameAr is String) 'nameAr': nameAr,
    if (nameEn is String) 'nameEn': nameEn,
  });
}

/// `lib/features/notifications/data/reminder_settings.dart`.
const String backupKeyAzkarReminderEnabled = 'azkar_reminder_enabled';
const String backupKeyAzkarReminderTime = 'azkar_reminder_time';
const String backupKeyWirdReminderEnabled = 'wird_reminder_enabled';
const String backupKeyWirdReminderTime = 'wird_reminder_time';
const String backupKeyPrayerReminderEnabled = 'prayer_reminder_enabled';

/// `lib/core/domain/prayer_config.dart`.
const String backupKeyPrayerCalcMethod = 'prayer_calc_method';
const String backupKeyPrayerMadhab = 'prayer_madhab';
const String backupKeyPrayerEnabledPrayers = 'prayer_enabled_prayers';
const String backupKeyPrayerPreAdhanMinutes = 'prayer_pre_adhan_minutes';

/// `lib/features/quran/data/reader_settings_repository.dart`.
const String backupKeyReaderFontScale = 'reader_font_scale';

/// `lib/features/azkar/data/azkar_saved_state_repository.dart`.
const String backupKeyAzkarProgress = 'azkar_progress_v1';
const String backupKeyAzkarFavorites = 'azkar_favorites_v1';

/// `lib/features/prayer/data/city_repository.dart`.
const String backupKeySelectedCity = 'selected_city';

/// `lib/features/quran/data/last_read_repository.dart`.
const String backupKeyLastReadAyahId = 'last_read_ayah_id';

/// `lib/features/recitation/data/reciter_repository.dart`.
const String backupKeySelectedMoshafRow = 'selected_moshaf_row';

/// `lib/core/domain/adhan_preferences.dart`.
const String backupKeyAdhanId = 'adhan_id';
const String backupKeyAdhanFajrId = 'adhan_fajr_id';

/// `lib/features/tasbih/data/tasbih_repository.dart`.
const String backupKeyTasbihState = 'tasbih_state';

/// The settings keys a restore may import (import wins, key-by-key).
///
/// Every user preference the app persists belongs here: losing it on a
/// restore would silently reset the user's configuration. The last-read
/// pointer and tasbih state travel as their own typed entities and are
/// deliberately NOT part of this map; app-managed keys such as
/// `content_version` are deliberately excluded.
const Set<String> kBackupSettingsWhitelist = {
  backupKeyAzkarReminderEnabled,
  backupKeyAzkarReminderTime,
  backupKeyWirdReminderEnabled,
  backupKeyWirdReminderTime,
  backupKeyPrayerReminderEnabled,
  backupKeyPrayerCalcMethod,
  backupKeyPrayerMadhab,
  backupKeyPrayerEnabledPrayers,
  backupKeyPrayerPreAdhanMinutes,
  backupKeyReaderFontScale,
  backupKeyAzkarProgress,
  backupKeyAzkarFavorites,
  backupKeySelectedCity,
  backupKeySelectedMoshafRow,
  backupKeyAdhanId,
  backupKeyAdhanFajrId,
};

/// Keys whose change needs a reminder re-plan after apply — mirrors the boot
/// scheduler inputs (city, azkar/wird settings and the whole prayer
/// configuration; see `scheduleReminders`).
const Set<String> kBackupReminderRelevantKeys = {
  backupKeyAzkarReminderEnabled,
  backupKeyAzkarReminderTime,
  backupKeyWirdReminderEnabled,
  backupKeyWirdReminderTime,
  backupKeyPrayerReminderEnabled,
  backupKeyPrayerCalcMethod,
  backupKeyPrayerMadhab,
  backupKeyPrayerEnabledPrayers,
  backupKeyPrayerPreAdhanMinutes,
  backupKeySelectedCity,
  backupKeyAdhanId,
  backupKeyAdhanFajrId,
};
