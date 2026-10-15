import 'dart:convert';

import '../../../core/db/app_database.dart';

const tasbihStateKey = 'tasbih_state';

class TasbihSnapshot {
  const TasbihSnapshot({required this.count, required this.target});

  final int count;
  final int target;
}

class TasbihRepository {
  TasbihRepository(this._db);

  final AppDatabase _db;

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

  Future<void> save(int count, int target) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: tasbihStateKey,
            value: jsonEncode({'count': count, 'target': target}),
          ),
        );
  }
}
