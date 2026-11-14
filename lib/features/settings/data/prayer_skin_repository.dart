import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/prayer_skin.dart';

/// Stores the prayer-skin preference in the local settings table.
///
/// A twin of `AppThemeRepository`: the two preferences have the same shape, and
/// a generic would only be worth it when a third one appears.
class PrayerSkinRepository implements PrayerSkinSource {
  /// Creates the repository over the app database.
  PrayerSkinRepository(this._db);

  /// Settings key (device-scoped: never exported by a backup).
  static const key = 'prayer_skin_mode';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<PrayerSkinMode> load() async =>
      PrayerSkinMode.fromCode(await _settings.read(key));

  @override
  Future<void> save(PrayerSkinMode mode) => _settings.write(key, mode.code);
}
