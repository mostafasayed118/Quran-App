import 'dart:convert';

import '../../../core/db/app_database.dart';

const tasbihStateKey = 'tasbih_state';

/// The stored tasbih counter and its goal.
class TasbihSnapshot {
  const TasbihSnapshot({required this.count, required this.target});

  /// Current number of repetitions.
  final int count;

  /// Repetition goal.
  final int target;
}

/// Stores the tasbih counter in the local database.
class TasbihRepository {
  TasbihRepository(this._db);

  final AppDatabase _db;

  /// The stored counter, or null when the user never used tasbih.
  Future<TasbihSnapshot?> load() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(tasbihStateKey)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final json = jsonDecode(row.value) as Map<String, dynamic>;
      return TasbihSnapshot(
        count: (json['count'] as num).toInt(),
        target: (json['target'] as num).toInt(),
      );
    } on Object {
      return null;
    }
  }

  /// Stores [count] and [target] as the tasbih counter.
  Future<void> save(int count, int target) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: tasbihStateKey,
            value: jsonEncode({'count': count, 'target': target}),
          ),
        );
  }
}
