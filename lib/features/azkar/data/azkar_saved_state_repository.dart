import 'dart:convert';

import '../../../core/db/app_database.dart';
import 'azkar_saved_state.dart';

/// Stores [AzkarSavedState] in the settings table.
///
/// Two keys keep a counter write from rewriting the favorites list: the
/// progress row is one JSON object keyed by collection id, the favorites row is
/// one JSON array.
class AzkarSavedStateRepository implements AzkarSavedStateSource {
  /// Creates the repository over [db].
  AzkarSavedStateRepository(this._db);

  /// Progress key; v1 so a future shape change cannot read old bytes.
  static const progressKey = 'azkar_progress_v1';

  /// Favorites key.
  static const favoritesKey = 'azkar_favorites_v1';

  final AppDatabase _db;

  @override
  Future<AzkarSavedState> load() async {
    final rows = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.isIn([progressKey, favoritesKey])))
        .get();
    final byKey = {
      for (final row in rows) row.key: row.value,
    };
    return AzkarSavedState(
      remaining: _decodeProgress(byKey[progressKey]),
      favorites: _decodeFavorites(byKey[favoritesKey]),
    );
  }

  @override
  Future<void> saveRemaining(String collectionId, List<int> remaining) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(progressKey)))
        .getSingleOrNull();
    final progress = _decodeProgress(row?.value);
    progress[collectionId] = List<int>.unmodifiable(remaining);
    await _write(progressKey, jsonEncode(progress));
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) =>
      _write(favoritesKey, jsonEncode(favorites.toList()));

  Future<void> _write(String key, String value) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  static Map<String, List<int>> _decodeProgress(String? raw) {
    if (raw == null || raw.isEmpty) return <String, List<int>>{};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final progress = <String, List<int>>{};
      for (final entry in json.entries) {
        final counts = entry.value;
        if (counts is! List) continue;
        progress[entry.key] = <int>[
          for (final count in counts)
            if (count is num) count.toInt(),
        ];
      }
      return progress;
    } on Object {
      return <String, List<int>>{};
    }
  }

  static Set<String> _decodeFavorites(String? raw) {
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final json = jsonDecode(raw);
      if (json is! List) return <String>{};
      return <String>{
        for (final id in json)
          if (id is String && id.isNotEmpty) id,
      };
    } on Object {
      return <String>{};
    }
  }
}
