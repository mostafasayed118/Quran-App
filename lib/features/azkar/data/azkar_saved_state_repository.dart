import 'dart:convert';

import '../../../core/db/app_database.dart';
import 'azkar_saved_state.dart';

/// Stores [AzkarSavedState] in the settings table.
///
/// Two keys keep a counter write from rewriting the favorites list: the
/// progress row is one JSON object (`day` + `counts` keyed by collection id),
/// the favorites row is one JSON array.
class AzkarSavedStateRepository implements AzkarSavedStateSource {
  /// Creates the repository over [db].
  AzkarSavedStateRepository(this._db);

  /// Progress key; v1 so a future shape change cannot read old bytes.
  static const progressKey = 'azkar_progress_v1';

  /// Favorites key.
  static const favoritesKey = 'azkar_favorites_v1';

  final AppDatabase _db;

  /// Tail of the progress write chain.
  ///
  /// A save is a read-modify-write over ONE JSON row: two overlapping saves
  /// (a tap, back, tap another collection) can both read the same row before
  /// either writes, and the second would drop the first collection's update.
  /// Writes are chained so each merge sees the previous result.
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<AzkarSavedState> load() async {
    final rows = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.isIn([progressKey, favoritesKey])))
        .get();
    final byKey = {
      for (final row in rows) row.key: row.value,
    };
    final progress = _decodeProgress(byKey[progressKey]);
    return AzkarSavedState(
      day: progress.day,
      remaining: progress.counts,
      favorites: _decodeFavorites(byKey[favoritesKey]),
    );
  }

  @override
  Future<void> saveRemaining(
    String collectionId,
    List<int> remaining,
    String day,
  ) {
    final previous = _writeQueue;
    final run = () async {
      try {
        await previous;
      } on Object {
        // A failed earlier write must not block this one.
      }
      final row = await (_db.select(_db.settingsTable)
            ..where((setting) => setting.key.equals(progressKey)))
          .getSingleOrNull();
      final stored = _decodeProgress(row?.value);
      // A new day starts a fresh set: yesterday's counters must not ride along.
      final counts = stored.day == day
          ? <String, List<int>>{...stored.counts}
          : <String, List<int>>{};
      counts[collectionId] = List<int>.unmodifiable(remaining);
      await _write(
        progressKey,
        jsonEncode({'day': day, 'counts': counts}),
      );
    }();
    _writeQueue = run;
    return run;
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) =>
      _write(favoritesKey, jsonEncode(favorites.toList()));

  Future<void> _write(String key, String value) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  static ({String day, Map<String, List<int>> counts}) _decodeProgress(
    String? raw,
  ) {
    const empty = (day: '', counts: <String, List<int>>{});
    if (raw == null || raw.isEmpty) return empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return empty;
      final day = json['day'];
      final counts = json['counts'];
      if (counts is! Map<String, dynamic>) return empty;
      final decoded = <String, List<int>>{};
      for (final entry in counts.entries) {
        final values = entry.value;
        if (values is! List) continue;
        decoded[entry.key] = <int>[
          for (final value in values)
            if (value is num) value.toInt(),
        ];
      }
      return (day: day is String ? day : '', counts: decoded);
    } on Object {
      return empty;
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
