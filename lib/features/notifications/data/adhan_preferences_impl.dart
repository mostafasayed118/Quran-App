import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';

/// Settings-table storage for the adhan selection.
///
/// Mirrors `ReminderSettings`: a plain key/value row per preference, no JSON.
/// Both reads normalise against the catalog, so a stored id this build does not
/// ship can never reach the notification plan.
class AdhanPreferencesImpl implements AdhanPreferences {
  /// Creates the store over [db] (the shared app database).
  AdhanPreferencesImpl(this._db);

  final AppDatabase _db;

  @override
  Future<String> adhanId() async => adhanById(await _read(adhanIdKey)).id;

  @override
  Future<String?> fajrAdhanId() async {
    final stored = await _read(adhanFajrIdKey);
    if (stored == null) return null;
    // A removed or unrecognised track means "same as default", not a dead id:
    // otherwise the Fajr notification would fall back to nothing at all.
    return adhanById(stored).id == stored ? stored : null;
  }

  @override
  Future<void> setAdhanId(String id) => _write(adhanIdKey, id);

  @override
  Future<void> setFajrAdhanId(String? id) => _write(adhanFajrIdKey, id ?? '');

  Future<String?> _read(String key) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    final value = row?.value;
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _write(String key, String value) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }
}
