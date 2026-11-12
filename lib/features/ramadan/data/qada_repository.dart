import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import 'qada_source.dart';

/// Stores the missed-fast dates as one JSON array in the settings table.
///
/// The set is tiny (a few dozen dates at most), so a settings row is simpler
/// than a schema bump and follows the azkar/tasbih precedent.
class QadaRepository implements QadaSource {
  /// Creates the repository over [db].
  QadaRepository(this._db);

  /// The settings key; exported by the backup whitelist so a restore keeps
  /// the recorded days.
  static const key = 'qada_missed_fasts_v1';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<List<DateTime>> loadMissed() async =>
      _decode(await _settings.read(key));

  @override
  Future<void> saveMissed(List<DateTime> dates) => _settings.write(
        key,
        jsonEncode([
          for (final date in normalize(dates)) _encodeDate(date),
        ]),
      );

  /// Date-only, de-duplicated, ascending.
  static List<DateTime> normalize(Iterable<DateTime> dates) {
    final unique = <String, DateTime>{};
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      unique[_encodeDate(day)] = day;
    }
    final result = unique.values.toList()..sort((a, b) => a.compareTo(b));
    return result;
  }

  static List<DateTime> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const <DateTime>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <DateTime>[];
      final dates = <DateTime>[];
      for (final entry in decoded) {
        if (entry is! String) continue;
        final parsed = DateTime.tryParse(entry);
        if (parsed != null) dates.add(parsed);
      }
      return normalize(dates);
    } on Object {
      return const <DateTime>[];
    }
  }

  static String _encodeDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
