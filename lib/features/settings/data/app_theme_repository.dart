import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/app_theme.dart';

/// Stores the appearance preference in the local settings table.
///
/// Deliberately a twin of `AppLocaleRepository`: two 26-line classes stay
/// obvious, and a generic is only worth it when a third preference appears.
class AppThemeRepository implements AppThemeSource {
  /// Creates the repository over the app database.
  AppThemeRepository(this._db);

  /// Settings key (device-scoped: never exported by a backup).
  static const key = 'app_theme_mode';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<AppThemeMode> load() async =>
      AppThemeMode.fromCode(await _settings.read(key));

  @override
  Future<void> save(AppThemeMode mode) => _settings.write(key, mode.code);
}
