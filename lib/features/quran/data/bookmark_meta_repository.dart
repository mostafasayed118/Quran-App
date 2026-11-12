import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import 'bookmark_meta.dart';

/// Stores bookmark folders and notes as one JSON object in the settings table.
///
/// The data is small (one entry per annotated bookmark), so a settings row is
/// simpler than a schema bump and keeps the bookmark table untouched.
class BookmarkMetaRepository implements BookmarkMetaSource {
  /// Creates the repository over [db].
  BookmarkMetaRepository(this._db);

  /// The settings key; exported by the backup whitelist.
  static const key = 'bookmark_meta_v1';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async =>
      _decode(await _settings.read(key));

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> entries) {
    final normalized = normalize(entries);
    return _settings.write(
      key,
      jsonEncode(<String, dynamic>{
        for (final entry in normalized.entries)
          '${entry.key}': entry.value.toJson(),
      }),
    );
  }

  /// Trims every entry and drops entries with no folder and no note.
  static Map<int, BookmarkMetaEntry> normalize(
    Map<int, BookmarkMetaEntry> entries,
  ) {
    final result = <int, BookmarkMetaEntry>{};
    for (final entry in entries.entries) {
      final normalized = entry.value.normalized();
      if (!normalized.isEmpty) result[entry.key] = normalized;
    }
    return result;
  }

  static Map<int, BookmarkMetaEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const <int, BookmarkMetaEntry>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <int, BookmarkMetaEntry>{};
      final result = <int, BookmarkMetaEntry>{};
      for (final entry in decoded.entries) {
        final key = int.tryParse('${entry.key}');
        final value = entry.value;
        if (key == null || value is! Map) continue;
        final meta = BookmarkMetaEntry.fromJson(
          value.map((key, value) => MapEntry('$key', value)),
        );
        if (!meta.isEmpty) result[key] = meta;
      }
      return normalize(result);
    } on Object {
      return const <int, BookmarkMetaEntry>{};
    }
  }
}
