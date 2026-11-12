import 'app_database.dart';

/// The one access point for the key/value [SettingsTable].
///
/// Every settings-backed repository used to hand-roll the same
/// select-by-key + insert-on-conflict-update pair — twenty-odd copies of it
/// across the features. Centralising it keeps a single place to change the
/// storage contract (the backup whitelist, a future cache) and a single place
/// to test the round-trip.
///
/// This is deliberately a plain collaborator, not a port: a feature's `data/`
/// may depend on `core/db/`, and callers keep their own typed API.
class SettingsStore {
  /// Creates the store over [db].
  SettingsStore(this._db);

  final AppDatabase _db;

  /// The stored value for [key], or null when it was never written.
  Future<String?> read(String key) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// The stored values for [keys], keyed by setting name. Absent keys are
  /// omitted rather than mapped to null.
  Future<Map<String, String>> readAll(Iterable<String> keys) async {
    final wanted = keys.toSet();
    if (wanted.isEmpty) return const <String, String>{};
    final rows = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.isIn(wanted)))
        .get();
    return {for (final row in rows) row.key: row.value};
  }

  /// Inserts or replaces one setting.
  Future<void> write(String key, String value) =>
      writeAll(<String, String>{key: value});

  /// Inserts or replaces [values] in one batch, so a multi-key update cannot
  /// land half-applied.
  Future<void> writeAll(Map<String, String> values) async {
    if (values.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.settingsTable, [
        for (final entry in values.entries)
          SettingsTableCompanion.insert(key: entry.key, value: entry.value),
      ]);
    });
  }

  /// Deletes [key]; a missing key is a no-op.
  Future<void> remove(String key) async {
    await (_db.delete(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .go();
  }
}
