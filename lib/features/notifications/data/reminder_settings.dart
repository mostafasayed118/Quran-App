import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import 'reminder_planner.dart' show preAdhanReminderId;
import 'reminder_scheduling.dart';

/// The reminder settings keys (A1 supersedes the earlier two-key ruling:
/// prayer + azkar + wird).
const String azkarReminderEnabledKey = 'azkar_reminder_enabled';
const String azkarReminderTimeKey = 'azkar_reminder_time';
const String wirdReminderEnabledKey = 'wird_reminder_enabled';
const String wirdReminderTimeKey = 'wird_reminder_time';
const String prayerReminderEnabledKey = 'prayer_reminder_enabled';

/// Settings-table reads/writes for the reminder engine (W3 CityRepository
/// pattern; bool stored as the 'true'/'false' string, time as 'HH:mm').
class ReminderSettings
    implements ReminderSettingsPort, PrayerReminderSettingsPort {
  ReminderSettings(
    this._db, {
    PrayerConfigSource? prayerConfig,
    PreAdhanCanceller? preAdhanCanceller,
    AdhanPreferences? adhanPrefs,
  })  : _prayerConfig = prayerConfig,
        _preAdhanCanceller = preAdhanCanceller,
        _adhanPrefs = adhanPrefs;

  final AppDatabase _db;
  final PrayerConfigSource? _prayerConfig;
  final PreAdhanCanceller? _preAdhanCanceller;

  /// Optional for the same reason as `PrayerReminderSettingsPort`: existing
  /// constructions and test fakes predate the adhan picker and must keep
  /// compiling. Absent, every plan carries no adhan and the OS default sound
  /// plays — exactly the pre-feature behaviour.
  final AdhanPreferences? _adhanPrefs;

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

  /// Missing row means ENABLED, so every existing install keeps the prayer
  /// reminder it had before the toggle existed.
  @override
  Future<bool> prayerEnabled() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(prayerReminderEnabledKey)))
        .getSingleOrNull();
    return row?.value != 'false';
  }

  @override
  Future<void> setPrayerEnabled(bool enabled) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: prayerReminderEnabledKey,
            value: enabled ? 'true' : 'false',
          ),
        );
  }

  /// The shared (re)planning path (boot, prayer times, settings) — the
  /// notifications engine composes the plan; this class only owns the
  /// settings it reads.
  ///
  /// The port contract is "never throws": a failed prayer-toggle read
  /// degrades to the historical enabled behaviour instead of failing the
  /// re-plan.
  ///
  /// Calls are serialized: the callers fire replans unawaited, and an older
  /// snapshot (say the tap that turned the early reminder off) must never
  /// reach the scheduler after a newer one. The config is read inside the
  /// queued run, so the last caller always plans with the newest settings.
  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) {
    final previous = _rescheduleQueue;
    final run = () async {
      if (previous != null) {
        try {
          await previous;
        } on Object {
          // Every run swallows its own failures; keep the chain alive.
        }
      }
      await _rescheduleNow(city: city, prayer: prayer, scheduler: scheduler);
    }();
    _rescheduleQueue = run;
    return run;
  }

  Future<void> _rescheduleNow({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {
    var enabled = true;
    try {
      enabled = await prayerEnabled();
    } on Object {
      // Fall through with the default.
    }
    final config = _prayerConfig?.current ?? PrayerConfig.egyptian;
    final plan = await scheduleReminders(
      city: city,
      prayer: prayer,
      settings: this,
      scheduler: scheduler,
      prayerEnabled: enabled,
      adhanPrefs: _adhanPrefs,
      config: config,
    );
    // The optional id 4 is not one of the fixed planner ids, so a plan that
    // omits it (master switch off, no enabled prayer, a zero lead time, or a
    // lead time that already passed) must clear it explicitly — including
    // after a restart, when the binding has no memory of the last plan.
    if (!plan.any((reminder) => reminder.id == preAdhanReminderId)) {
      await _preAdhanCanceller?.cancelPreAdhan();
    }
  }

  /// The tail of the reschedule chain (see [reschedule]).
  Future<void>? _rescheduleQueue;
}
