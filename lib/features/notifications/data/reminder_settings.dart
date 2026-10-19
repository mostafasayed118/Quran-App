import 'package:quran_yahdi/core/db/app_database.dart';

/// The reminder settings keys (A1 supersedes the earlier two-key ruling:
/// prayer + azkar + wird).
const String azkarReminderEnabledKey = 'azkar_reminder_enabled';
const String azkarReminderTimeKey = 'azkar_reminder_time';
const String wirdReminderEnabledKey = 'wird_reminder_enabled';
const String wirdReminderTimeKey = 'wird_reminder_time';

/// Settings-table reads/writes for the reminder engine (W3 CityRepository
/// pattern; bool stored as the 'true'/'false' string, time as 'HH:mm').
class ReminderSettings {
  ReminderSettings(this._db);

  final AppDatabase _db;

  Future<bool> azkarEnabled() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(azkarReminderEnabledKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<String?> azkarTimeHm() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(azkarReminderTimeKey)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setAzkarEnabled(bool enabled) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: azkarReminderEnabledKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  Future<void> setAzkarTime(String hm) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: azkarReminderTimeKey, value: hm),
        );
  }

  Future<bool> wirdEnabled() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(wirdReminderEnabledKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<String?> wirdTimeHm() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(wirdReminderTimeKey)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setWirdEnabled(bool enabled) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: wirdReminderEnabledKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  Future<void> setWirdTime(String hm) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: wirdReminderTimeKey, value: hm),
        );
  }
}
