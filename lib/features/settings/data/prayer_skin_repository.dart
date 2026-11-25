import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/prayer_skin.dart';

/// Stores the prayer-skin preference in the local settings table.
///
/// A thin typed wrapper over [SettingsStore] for the device-scoped
/// `prayer_skin_mode` key — one of 22 per-feature wrappers that map a typed
/// value onto a settings row. The preference is per device and is never
/// exported by a backup. It mirrors `AppThemeRepository`'s shape; a generic
/// would only be worth it when a third wrapper needs the same mapping.
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
