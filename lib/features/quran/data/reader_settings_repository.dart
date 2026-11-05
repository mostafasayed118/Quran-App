import '../../../core/db/app_database.dart';
import 'reader_layout_source.dart';
import 'reader_settings_source.dart';

/// Stores the reader display preferences in the existing settings table.
class ReaderSettingsRepository
    implements ReaderSettingsSource, ReaderLayoutSource {
  /// Creates the repository over [db].
  ReaderSettingsRepository(this._db);

  /// The settings key; exported by the backup whitelist so a restore keeps
  /// the user's chosen reading size.
  static const fontScaleKey = 'reader_font_scale';

  /// The settings key for the line-height multiplier.
  static const lineHeightKey = 'reader_line_height';

  /// The historical line height of the verse and mushaf text.
  static const defaultLineHeight = ReaderLayoutSource.defaultLineHeight;

  /// The narrowest and widest line height the reader accepts.
  static const minLineHeight = ReaderLayoutSource.minLineHeight;
  static const maxLineHeight = ReaderLayoutSource.maxLineHeight;

  final AppDatabase _db;

  @override
  Future<double> loadFontScale() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(fontScaleKey)))
        .getSingleOrNull();
    final parsed = double.tryParse(row?.value ?? '');
    if (parsed == null) return 1;
    return _clampScale(parsed);
  }

  @override
  Future<void> saveFontScale(double scale) async {
    await _write(fontScaleKey, '${_clampScale(scale)}');
  }

  @override
  Future<double> loadLineHeight() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(lineHeightKey)))
        .getSingleOrNull();
    final parsed = double.tryParse(row?.value ?? '');
    if (parsed == null) return defaultLineHeight;
    return _clampLineHeight(parsed);
  }

  @override
  Future<void> saveLineHeight(double lineHeight) async {
    await _write(lineHeightKey, '${_clampLineHeight(lineHeight)}');
  }

  Future<void> _write(String key, String value) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  static double _clampScale(double value) {
    if (value < 0.8) return 0.8;
    if (value > 2.0) return 2.0;
    return value;
  }

  static double _clampLineHeight(double value) {
    if (value < minLineHeight) return minLineHeight;
    if (value > maxLineHeight) return maxLineHeight;
    return value;
  }
}
