import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'pack_reader.dart';

/// DB-backed read index for installed hadith packs.
///
/// The pack JSON stays the canonical artifact; this store imports its compact
/// `(number, text)` rows once and then serves pages with SQL LIMIT/OFFSET.
/// That keeps the browse screen's memory bounded by one page even when a pack
/// grows to tens of thousands of hadiths.
///
/// The table is created lazily on first use (raw SQL, deliberately outside the
/// drift schema) so merely opening the app never changes the migration
/// contract or the pinned table census.
class HadithStore {
  HadithStore(
    this._db, {
    required Future<String?> Function(String packId) packPath,
    Future<dynamic> Function(String path)? fileDecoder,
  })  : _packPath = packPath,
        _fileDecoder = fileDecoder;

  final AppDatabase _db;
  final Future<String?> Function(String packId) _packPath;
  final Future<dynamic> Function(String path)? _fileDecoder;

  /// Rows per insert batch: small enough to keep the argument list bounded,
  /// large enough to keep the one-time import quick.
  static const int _importChunk = 500;

  /// Single-flight imports, keyed by pack id, so the install path and a
  /// concurrent first page cannot import the same pack twice.
  final Map<String, Future<void>> _imports = {};

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    if (offset < 0 || limit <= 0) {
      return (const <(int, String)>[], false);
    }
    await _ensureTable();
    var total = await _count(packId);
    if (total == 0) {
      // Upgrade path: packs installed before the DB index existed import on
      // their first browse instead of at boot.
      await _ensureImported(packId);
      total = await _count(packId);
    }
    if (total == 0 || offset >= total) {
      return (const <(int, String)>[], false);
    }
    final rows = await _db.customSelect(
      'SELECT number, body FROM hadith_entries WHERE pack_id = ? '
      'ORDER BY ordinal LIMIT ? OFFSET ?',
      variables: [
        Variable.withString(packId),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
    ).get();
    final items = <(int, String)>[
      // Malformed source slots keep their ordinal (so hasMore stays exact)
      // but are filtered from the page. Empty text is a valid value: the UI
      // hides it, exactly like the in-memory reader did.
      for (final row in rows)
        if (row.read<int>('number') >= 0)
          (row.read<int>('number'), row.read<String>('body')),
    ];
    return (items, offset + limit < total);
  }

  /// Imports a projection produced by the install sniff, replacing any rows
  /// already stored for [packId].
  Future<void> importProjection(String packId, Object? projection) {
    final compact = _compact(projection);
    if (compact == null) return Future<void>.value();
    return _runImport(packId, () async {
      await _ensureTable();
      await _write(packId, compact);
    });
  }

  /// Drops the imported rows of an uninstalled pack.
  ///
  /// Never creates the table: an install that never browsed hadiths should
  /// not leave a derived table behind.
  Future<void> deletePack(String packId) async {
    final exists = await _db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' "
          "AND name = 'hadith_entries' LIMIT 1",
        )
        .getSingleOrNull();
    if (exists == null) return;
    await _db.customStatement(
        'DELETE FROM hadith_entries WHERE pack_id = ?', [packId]);
  }

  Future<void> _ensureImported(String packId) => _runImport(packId, () async {
        if (await _count(packId) > 0) return;
        final path = await _packPath(packId);
        if (path == null) return;
        final compact = await _decode(path);
        if (compact == null) return;
        await _write(packId, compact);
      });

  Future<void> _runImport(String packId, Future<void> Function() action) {
    final pending = _imports[packId];
    if (pending != null) return pending;
    final task = action();
    _imports[packId] = task;
    return task.whenComplete(() {
      if (identical(_imports[packId], task)) _imports.remove(packId);
    });
  }

  Future<void> _ensureTable() => _db.customStatement(
        'CREATE TABLE IF NOT EXISTS hadith_entries '
        '(pack_id TEXT NOT NULL, ordinal INTEGER NOT NULL, '
        'number INTEGER NOT NULL, body TEXT NOT NULL, '
        'PRIMARY KEY (pack_id, ordinal))',
      );

  Future<int> _count(String packId) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM hadith_entries WHERE pack_id = ?',
      variables: [Variable.withString(packId)],
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> _write(String packId, List<(int, String)?> compact) async {
    await _db.transaction(() async {
      await _db.customStatement(
          'DELETE FROM hadith_entries WHERE pack_id = ?', [packId]);
      for (var start = 0; start < compact.length; start += _importChunk) {
        final end = start + _importChunk < compact.length
            ? start + _importChunk
            : compact.length;
        await _db.batch((batch) {
          for (var i = start; i < end; i++) {
            final entry = compact[i];
            batch.customStatement(
              'INSERT INTO hadith_entries(pack_id, ordinal, number, body) '
              'VALUES (?, ?, ?, ?)',
              [packId, i, entry?.$1 ?? -1, entry?.$2 ?? ''],
            );
          }
        });
      }
    });
  }

  Future<List<(int, String)?>?> _decode(String path) async {
    final injected = _fileDecoder;
    if (injected != null) {
      try {
        final decoded = await injected(path);
        if (decoded is! Map<String, dynamic>) return null;
        final list = decoded['hadiths'];
        if (list is! List) return null;
        return PackReader.buildHadithList(list);
      } on Object {
        return null;
      }
    }
    return PackReader.decodeHadithProjectionInIsolate(path);
  }

  static List<(int, String)?>? _compact(Object? projection) {
    if (projection is List<(int, String)?>) return projection;
    if (projection is List) return PackReader.buildHadithList(projection);
    return null;
  }
}
