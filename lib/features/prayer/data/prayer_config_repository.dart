import 'dart:async';

import '../../../core/db/app_database.dart';
import '../../../core/domain/prayer_config.dart';

/// Persists the prayer calculation preferences in the settings table.
///
/// The table is the existing key/value store; no schema change is needed. The
/// in-memory [current] is what the synchronous `PrayerTimesPort` reads.
class PrayerConfigRepository implements PrayerConfigSource {
  /// Creates the repository over the app database.
  PrayerConfigRepository(this._db);

  final AppDatabase _db;
  final StreamController<PrayerConfig> _changes =
      StreamController<PrayerConfig>.broadcast();
  PrayerConfig _current = PrayerConfig.egyptian;

  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => _changes.stream;

  @override
  Future<PrayerConfig> load() async {
    try {
      final rows = await (_db.select(_db.settingsTable)
            ..where((t) => t.key.isIn(
                  [
                    PrayerConfig.methodKey,
                    PrayerConfig.madhabKey,
                    PrayerConfig.enabledPrayersKey,
                    PrayerConfig.preAdhanMinutesKey,
                    PrayerConfig.fajrFollowUpKey,
                    PrayerConfig.adjustmentsKey,
                    PrayerConfig.highLatitudeKey,
                  ],
                )))
          .get();
      final values = <String, String>{
        for (final row in rows) row.key: row.value,
      };
      final loaded = PrayerConfig.fromJson(values);
      if (loaded != _current) {
        _current = loaded;
        _changes.add(loaded);
      }
      return loaded;
    } on Object {
      // A missing or unreadable row must never block boot: the historical
      // Egyptian/Shafi defaults are already in [current].
      return _current;
    }
  }

  @override
  Future<void> save(PrayerConfig config) async {
    await _db.transaction(() async {
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.methodKey,
              value: config.method.name,
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.madhabKey,
              value: config.madhab.name,
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.enabledPrayersKey,
              value:
                  config.enabledPrayers.map((prayer) => prayer.name).join(','),
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.preAdhanMinutesKey,
              value: '${config.preAdhanMinutes}',
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.fajrFollowUpKey,
              value: config.fajrFollowUp ? 'true' : 'false',
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.adjustmentsKey,
              value: config.toJson()[PrayerConfig.adjustmentsKey] ?? '',
            ),
          );
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              key: PrayerConfig.highLatitudeKey,
              value: config.highLatitude.name,
            ),
          );
    });
    _current = config;
    _changes.add(config);
  }
}
