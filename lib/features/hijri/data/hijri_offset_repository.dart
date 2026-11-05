import '../../../core/db/app_database.dart';
import 'hijri_offset_source.dart';
import 'hijri_service.dart';

/// Stores the local Hijri correction in the existing settings table.
class HijriOffsetRepository implements HijriOffsetSource {
  /// Creates the repository over [db].
  HijriOffsetRepository(this._db);

  /// The settings key; exported by the backup whitelist so a restore keeps
  /// the user's local convention.
  static const key = 'hijri_day_offset';

  final AppDatabase _db;

  @override
  Future<int> loadOffsetDays() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    if (parsed == null) return 0;
    return _clamp(parsed);
  }

  @override
  Future<void> saveOffsetDays(int days) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: key,
            value: '${_clamp(days)}',
          ),
        );
  }

  static int _clamp(int value) {
    if (value < HijriService.minOffsetDays) return HijriService.minOffsetDays;
    if (value > HijriService.maxOffsetDays) return HijriService.maxOffsetDays;
    return value;
  }
}
