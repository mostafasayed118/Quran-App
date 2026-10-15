import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// One readable bookmark row: the bookmark joined with its ayah.
class BookmarkEntry {
  const BookmarkEntry({required this.ayah});

  final Ayah ayah;
}

class AyahRepository {
  AyahRepository(this._db);

  final AppDatabase _db;

  Future<List<Ayah>> surahAyahs(int surahId) {
    final query = _db.select(_db.ayahs)
      ..where((a) => a.surahId.equals(surahId))
      ..orderBy([(a) => OrderingTerm.asc(a.numberInSurah)]);
    return query.get();
  }

  Future<Surah?> surahById(int surahId) =>
      (_db.select(_db.surahs)..where((s) => s.id.equals(surahId)))
          .getSingleOrNull();

  Future<void> toggleBookmark(int ayahId) async {
    final existing = await (_db.select(_db.bookmarks)
          ..where((b) => b.ayahId.equals(ayahId)))
        .get();
    if (existing.isEmpty) {
      await _db.into(_db.bookmarks)
          .insert(BookmarksCompanion.insert(ayahId: ayahId));
    } else {
      await (_db.delete(_db.bookmarks)
            ..where((b) => b.ayahId.equals(ayahId)))
          .go();
    }
  }

  Stream<Set<int>> watchBookmarkedIds() {
    return _db.select(_db.bookmarks).watch().map(
          (rows) => rows.map((b) => b.ayahId).toSet(),
        );
  }

  Stream<List<BookmarkEntry>> watchBookmarkEntries() {
    final query = _db.select(_db.bookmarks).join([
      innerJoin(_db.ayahs, _db.ayahs.id.equalsExp(_db.bookmarks.ayahId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.bookmarks.id)]);
    return query.watch().map(
          (rows) => rows
              .map((row) => BookmarkEntry(ayah: row.readTable(_db.ayahs)))
              .toList(),
        );
  }
}
