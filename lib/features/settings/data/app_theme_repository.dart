import '../../../core/db/app_database.dart';
import '../../../core/domain/app_theme.dart';

/// Stores the appearance preference in the local settings table.
class AppThemeRepository implements AppThemeSource {
  /// Creates the repository over the app database.
  AppThemeRepository(this._db);

  /// Settings key (device-scoped: never exported by a backup).
  static const key = 'app_theme_mode';

  final AppDatabase _db;

  @override
  Future<AppThemeMode> load() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    return AppThemeMode.fromCode(row?.value);
  }

  @override
  Future<void> save(AppThemeMode mode) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: key,
            value: mode.code,
          ),
        );
  }
}
