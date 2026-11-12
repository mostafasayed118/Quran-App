import 'dart:async';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/prayer_config.dart';

/// Persists the prayer calculation preferences in the settings table.
///
/// The table is the existing key/value store; no schema change is needed. The
/// in-memory [current] is what the synchronous `PrayerTimesPort` reads.
class PrayerConfigRepository implements PrayerConfigSource {
  /// Creates the repository over the app database.
  PrayerConfigRepository(this._db);

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);
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
      final values = await _settings.readAll([
        PrayerConfig.methodKey,
        PrayerConfig.madhabKey,
        PrayerConfig.enabledPrayersKey,
        PrayerConfig.preAdhanMinutesKey,
        PrayerConfig.fajrFollowUpKey,
        PrayerConfig.adjustmentsKey,
        PrayerConfig.highLatitudeKey,
      ]);
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
    await _settings.writeAll(<String, String>{
      PrayerConfig.methodKey: config.method.name,
      PrayerConfig.madhabKey: config.madhab.name,
      PrayerConfig.enabledPrayersKey:
          config.enabledPrayers.map((prayer) => prayer.name).join(','),
      PrayerConfig.preAdhanMinutesKey: '${config.preAdhanMinutes}',
      PrayerConfig.fajrFollowUpKey: config.fajrFollowUp ? 'true' : 'false',
      PrayerConfig.adjustmentsKey:
          config.toJson()[PrayerConfig.adjustmentsKey] ?? '',
      PrayerConfig.highLatitudeKey: config.highLatitude.name,
    });
    _current = config;
    _changes.add(config);
  }
}
