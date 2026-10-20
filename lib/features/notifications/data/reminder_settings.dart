import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import 'reminder_scheduling.dart';

/// The reminder settings keys (A1 supersedes the earlier two-key ruling:
/// prayer + azkar + wird).
const String azkarReminderEnabledKey = 'azkar_reminder_enabled';
const String azkarReminderTimeKey = 'azkar_reminder_time';
const String wirdReminderEnabledKey = 'wird_reminder_enabled';
const String wirdReminderTimeKey = 'wird_reminder_time';

/// Settings-table reads/writes for the reminder engine (W3 CityRepository
/// pattern; bool stored as the 'true'/'false' string, time as 'HH:mm').
class ReminderSettings implements ReminderSettingsPort {
  ReminderSettings(this._db);

  final AppDatabase _db;

  @override
  Future<bool> azkarEnabled() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(azkarReminderEnabledKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  @override
  Future<String?> azkarTimeHm() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(azkarReminderTimeKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setAzkarEnabled(bool enabled) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: azkarReminderEnabledKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  @override
  Future<void> setAzkarTime(String hm) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: azkarReminderTimeKey, value: hm),
        );
  }

  @override
  Future<bool> wirdEnabled() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(wirdReminderEnabledKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  @override
  Future<String?> wirdTimeHm() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(wirdReminderTimeKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setWirdEnabled(bool enabled) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: wirdReminderEnabledKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  @override
  Future<void> setWirdTime(String hm) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: wirdReminderTimeKey, value: hm),
        );
  }

  /// The shared (re)planning path (boot, prayer times, settings) — the
  /// notifications engine composes the plan; this class only owns the
  /// settings it reads.
  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) =>
      scheduleReminders(
        city: city,
        prayer: prayer,
        settings: this,
        scheduler: scheduler,
      );
}
