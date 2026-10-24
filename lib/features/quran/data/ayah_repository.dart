import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'ayah_source.dart';

/// One readable bookmark row: the bookmark joined with its ayah.
class BookmarkEntry {
  /// A bookmark together with the ayah it points at.
  const BookmarkEntry({required this.ayah});

  /// The bookmarked ayah.
  final Ayah ayah;
}

/// Reads ayahs and bookmarks from the local database.
class AyahRepository implements AyahSource {
  AyahRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Ayah>> surahAyahs(int surahId) {
    final query = _db.select(_db.ayahs)
      ..where((a) => a.surahId.equals(surahId))
      ..orderBy([(a) => OrderingTerm.asc(a.numberInSurah)]);
    return query.get();
  }

  @override
  Future<Surah?> surahById(int surahId) =>
      (_db.select(_db.surahs)..where((s) => s.id.equals(surahId)))
          .getSingleOrNull();

  /// Single ayah lookup for the home continue-reading card (W3).
  @override
  Future<Ayah?> ayahById(int ayahId) =>
      (_db.select(_db.ayahs)..where((a) => a.id.equals(ayahId)))
          .getSingleOrNull();

  /// Ordered range of ayahs for ruqyah references (W4 mirror query).
  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah) {
    final query = _db.select(_db.ayahs)
      ..where((a) =>
          a.surahId.equals(surahId) &
          a.numberInSurah.isBiggerOrEqualValue(fromAyah) &
          a.numberInSurah.isSmallerOrEqualValue(toAyah))
      ..orderBy([(a) => OrderingTerm.asc(a.numberInSurah)]);
    return query.get();
  }

  @override
  Future<void> toggleBookmark(int ayahId) async {
    final existing = await (_db.select(_db.bookmarks)
          ..where((b) => b.ayahId.equals(ayahId)))
        .get();
    if (existing.isEmpty) {
      await _db
          .into(_db.bookmarks)
          .insert(BookmarksCompanion.insert(ayahId: ayahId));
    } else {
      await (_db.delete(_db.bookmarks)..where((b) => b.ayahId.equals(ayahId)))
          .go();
    }
  }

  @override
  Future<void> deleteBookmark(int ayahId) async {
    await (_db.delete(_db.bookmarks)..where((b) => b.ayahId.equals(ayahId)))
        .go();
  }

  @override
  Stream<Set<int>> watchBookmarkedIds() {
    return _db.select(_db.bookmarks).watch().map(
          (rows) => rows.map((b) => b.ayahId).toSet(),
        );
  }

  @override
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
