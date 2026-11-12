import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import 'last_read_source.dart';

const lastReadAyahIdKey = 'last_read_ayah_id';

/// Stores the last ayah the user read.
class LastReadRepository implements LastReadSource {
  LastReadRepository(this._db);

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<void> saveAyahId(int ayahId) =>
      _settings.write(lastReadAyahIdKey, ayahId.toString());

  @override
  Future<int?> loadAyahId() async =>
      int.tryParse(await _settings.read(lastReadAyahIdKey) ?? '');
}
