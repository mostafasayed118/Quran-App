import '../../../core/db/app_database.dart';

const lastReadAyahIdKey = 'last_read_ayah_id';

class LastReadRepository {
  LastReadRepository(this._db);

  final AppDatabase _db;

  Future<void> saveAyahId(int ayahId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: lastReadAyahIdKey,
            value: ayahId.toString(),
          ),
        );
  }

  Future<int?> loadAyahId() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(lastReadAyahIdKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return int.tryParse(row.value);
  }
}
