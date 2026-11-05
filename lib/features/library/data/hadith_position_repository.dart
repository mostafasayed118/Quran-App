import 'dart:convert';

import '../../../core/db/app_database.dart';
import 'hadith_personal.dart';

/// Stores the last browse offset per pack as one JSON object.
class HadithPositionRepository implements HadithPositionSource {
  /// Creates the repository over [db].
  HadithPositionRepository(this._db);

  /// The settings key; exported by the backup whitelist.
  static const key = 'hadith_positions_v1';

  final AppDatabase _db;

  @override
  Future<int> load(String packId) async {
    final all = await _readAll();
    return all[packId] ?? 0;
  }

  @override
  Future<void> save(String packId, int offset) async {
    final all = await _readAll();
    if (offset <= 0) {
      all.remove(packId);
    } else {
      all[packId] = offset;
    }
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: key,
            value: jsonEncode(all),
          ),
        );
  }

  Future<Map<String, int>> _readAll() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    final raw = row?.value;
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return <String, int>{
        for (final entry in decoded.entries)
          if (entry.value is int && (entry.value as int) >= 0)
            '${entry.key}': entry.value as int,
      };
    } on Object {
      return <String, int>{};
    }
  }
}
