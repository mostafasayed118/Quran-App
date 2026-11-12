import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/app_locale.dart';

/// Stores the language preference in the local settings table.
///
/// Deliberately a twin of `AppThemeRepository`: two 26-line classes stay
/// obvious, and a generic is only worth it when a third preference appears.
class AppLocaleRepository implements AppLocaleSource {
  /// Creates the repository over the app database.
  AppLocaleRepository(this._db);

  /// Settings key (device-scoped: never exported by a backup).
  static const key = 'app_locale';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<AppLanguage> load() async =>
      AppLanguage.fromCode(await _settings.read(key));

  @override
  Future<void> save(AppLanguage language) =>
      _settings.write(key, language.code);
}
