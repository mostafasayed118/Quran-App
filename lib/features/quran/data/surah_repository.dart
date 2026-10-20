import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/surah_summary.dart';
import 'surah_source.dart';
import 'verse_mapping.dart';

/// Reads surah metadata from the local database.
class SurahRepository implements SurahSource {
  SurahRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Surah>> watchAll() {
    final q = _db.select(_db.surahs)..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return q.watch();
  }

  /// The repository is the mapping boundary: rows are turned into domain
  /// entities here, so no presentation file ever imports a drift row.
  @override
  Stream<List<SurahSummary>> watchSummaries() =>
      watchAll().map((rows) => [for (final row in rows) row.toSummary()]);
}
