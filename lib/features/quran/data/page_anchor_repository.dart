import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/domain/quran_limits.dart';
import 'page_anchor_source.dart';

/// Reads the first ayah of a mushaf page from the shipped table.
class PageAnchorRepository implements PageAnchorSource {
  /// Creates the repository over [db].
  PageAnchorRepository(this._db);

  final AppDatabase _db;

  @override
  Future<({int surahId, int numberInSurah})?> anchorForPage(int page) async {
    if (page < 1 || page > kMushafPageCount) return null;
    final row = await (_db.select(_db.ayahs)
          ..where((ayah) => ayah.page.equals(page))
          ..orderBy([(ayah) => OrderingTerm.asc(ayah.id)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return (surahId: row.surahId, numberInSurah: row.numberInSurah);
  }
}
