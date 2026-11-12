import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import 'hadith_personal.dart';

/// Stores the last browse offset per pack as one JSON object.
class HadithPositionRepository implements HadithPositionSource {
  /// Creates the repository over [db].
  HadithPositionRepository(this._db);

  /// The settings key; exported by the backup whitelist.
  static const key = 'hadith_positions_v1';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

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
    await _settings.write(key, jsonEncode(all));
  }

  Future<Map<String, int>> _readAll() async {
    final raw = await _settings.read(key);
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
