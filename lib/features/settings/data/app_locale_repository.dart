import '../../../core/db/app_database.dart';
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

  @override
  Future<AppLanguage> load() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    return AppLanguage.fromCode(row?.value);
  }

  @override
  Future<void> save(AppLanguage language) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: key,
            value: language.code,
          ),
        );
  }
}
