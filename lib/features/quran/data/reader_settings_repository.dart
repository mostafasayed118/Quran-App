import '../../../core/db/app_database.dart';
import 'reader_settings_source.dart';

/// Stores the reader font scale in the existing settings table.
class ReaderSettingsRepository implements ReaderSettingsSource {
  /// Creates the repository over [db].
  ReaderSettingsRepository(this._db);

  /// The settings key; exported by the backup whitelist so a restore keeps
  /// the user's chosen reading size.
  static const fontScaleKey = 'reader_font_scale';

  final AppDatabase _db;

  @override
  Future<double> loadFontScale() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(fontScaleKey)))
        .getSingleOrNull();
    final parsed = double.tryParse(row?.value ?? '');
    if (parsed == null) return 1;
    return _clamp(parsed);
  }

  @override
  Future<void> saveFontScale(double scale) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: fontScaleKey,
            value: '${_clamp(scale)}',
          ),
        );
  }

  static double _clamp(double value) {
    if (value < 0.8) return 0.8;
    if (value > 2.0) return 2.0;
    return value;
  }
}
