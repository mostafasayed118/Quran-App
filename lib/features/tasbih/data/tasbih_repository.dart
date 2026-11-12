import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';

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

  late final SettingsStore _settings = SettingsStore(_db);

  /// The stored counter, or null when the user never used tasbih.
  Future<TasbihSnapshot?> load() async {
    final raw = await _settings.read(tasbihStateKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TasbihSnapshot(
        count: (json['count'] as num).toInt(),
        target: (json['target'] as num).toInt(),
      );
    } on Object {
      return null;
    }
  }

  /// Stores [count] and [target] as the tasbih counter.
  Future<void> save(int count, int target) => _settings.write(
        tasbihStateKey,
        jsonEncode({'count': count, 'target': target}),
      );
}
