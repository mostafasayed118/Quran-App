import '../../../core/db/app_database.dart';
import 'last_read_source.dart';

const lastReadAyahIdKey = 'last_read_ayah_id';

class LastReadRepository implements LastReadSource {
  LastReadRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveAyahId(int ayahId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: lastReadAyahIdKey,
            value: ayahId.toString(),
          ),
        );
  }

  @override
  Future<int?> loadAyahId() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(lastReadAyahIdKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return int.tryParse(row.value);
  }
}
