import 'dart:convert';

import '../../../core/db/app_database.dart';
import 'hadith_personal.dart';

/// Stores the hadith bookmarks as one JSON object in the settings table.
class HadithBookmarkRepository implements HadithBookmarkSource {
  /// Creates the repository over [db].
  HadithBookmarkRepository(this._db);

  /// The settings key; exported by the backup whitelist.
  static const key = 'hadith_bookmarks_v1';

  final AppDatabase _db;

  @override
  Future<Set<int>> load(String packId) async {
    final all = await _readAll();
    return all[packId] ?? const <int>{};
  }

  @override
  Future<void> save(String packId, Set<int> numbers) async {
    final all = await _readAll();
    if (numbers.isEmpty) {
      all.remove(packId);
    } else {
      all[packId] = numbers;
    }
    await _writeAll(all);
  }

  Future<Map<String, Set<int>>> _readAll() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    final raw = row?.value;
    if (raw == null || raw.isEmpty) return <String, Set<int>>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Set<int>>{};
      final result = <String, Set<int>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! List) continue;
        final numbers = <int>{
          for (final number in value)
            if (number is int && number >= 0) number,
        };
        if (numbers.isNotEmpty) result['${entry.key}'] = numbers;
      }
      return result;
    } on Object {
      return <String, Set<int>>{};
    }
  }

  Future<void> _writeAll(Map<String, Set<int>> all) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: key,
            value: jsonEncode(<String, dynamic>{
              for (final entry in all.entries)
                entry.key: (entry.value.toList()..sort()),
            }),
          ),
        );
  }
}
