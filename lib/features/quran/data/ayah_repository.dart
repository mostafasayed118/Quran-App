import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/domain/ayah_batch_lookup.dart';
import '../../../core/utils/app_log.dart';
import 'ayah_source.dart';
import 'bookmark_meta.dart';
import 'bookmark_pager.dart';

export 'bookmark_pager.dart'
    show BookmarkEntry, BookmarkPage, BookmarkPager, kBookmarkPageSize;

/// Reads ayahs and bookmarks from the local database.
class AyahRepository implements AyahSource, BookmarkPager, AyahBatchLookup {
  AyahRepository(this._db, {BookmarkMetaSource? meta}) : _meta = meta;

  final AppDatabase _db;
  final BookmarkMetaSource? _meta;

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

  /// One query for a whole set, used by the folder list.
  ///
  /// The per-id loop this replaces cost one serialized background-isolate
  /// round-trip per bookmark; a folder with fifty of them opened slowly.
  @override
  Future<List<Ayah>> ayahsByIds(List<int> ids) {
    if (ids.isEmpty) return Future<List<Ayah>>.value(const <Ayah>[]);
    return (_db.select(_db.ayahs)..where((a) => a.id.isIn(ids))).get();
  }

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
    final removed = await _db.transaction(() async {
      final existing = await (_db.select(_db.bookmarks)
            ..where((b) => b.ayahId.equals(ayahId)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.bookmarks).insert(
              BookmarksCompanion.insert(ayahId: ayahId),
              mode: InsertMode.insertOrIgnore,
            );
        return false;
      }
      await (_db.delete(_db.bookmarks)..where((b) => b.ayahId.equals(ayahId)))
          .go();
      return true;
    });
    if (removed) await _removeMeta(ayahId);
  }

  @override
  Future<void> deleteBookmark(int ayahId) async {
    await (_db.delete(_db.bookmarks)..where((b) => b.ayahId.equals(ayahId)))
        .go();
    await _removeMeta(ayahId);
  }

  /// Best-effort cleanup outside the bookmark transaction.
  ///
  /// The bookmark is the source of truth; a settings write failure must not
  /// turn a successful unbookmark into an error the user sees.
  Future<void> _removeMeta(int ayahId) async {
    final meta = _meta;
    if (meta == null) return;
    try {
      await removeBookmarkMeta(meta, ayahId);
    } on Object catch (error, stackTrace) {
      appLog('bookmark meta cleanup failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
    }
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
    return query.watch().map(_toEntries);
  }

  @override
  Stream<BookmarkPage> watchFirstPage({int limit = kBookmarkPageSize}) =>
      _firstPageQuery(limit).watch().map((rows) => _toPage(rows, limit));

  @override
  Future<BookmarkPage> entriesBefore(
    int beforeBookmarkId, {
    int limit = kBookmarkPageSize,
  }) async {
    final rows = await _olderPageQuery(beforeBookmarkId, limit).get();
    return _toPage(rows, limit);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _firstPageQuery(int limit) =>
      _db.select(_db.bookmarks).join([
        innerJoin(_db.ayahs, _db.ayahs.id.equalsExp(_db.bookmarks.ayahId)),
      ])
        ..orderBy([OrderingTerm.desc(_db.bookmarks.id)])
        ..limit(limit + 1);

  JoinedSelectStatement<HasResultSet, dynamic> _olderPageQuery(
    int beforeBookmarkId,
    int limit,
  ) =>
      _db.select(_db.bookmarks).join([
        innerJoin(_db.ayahs, _db.ayahs.id.equalsExp(_db.bookmarks.ayahId)),
      ])
        ..where(_db.bookmarks.id.isSmallerThanValue(beforeBookmarkId))
        ..orderBy([OrderingTerm.desc(_db.bookmarks.id)])
        ..limit(limit + 1);

  BookmarkPage _toPage(List<TypedResult> rows, int limit) {
    final entries = _toEntries(rows);
    final hasMore = entries.length > limit;
    return BookmarkPage(
      entries: hasMore ? entries.sublist(0, limit) : entries,
      hasMore: hasMore,
    );
  }

  List<BookmarkEntry> _toEntries(List<TypedResult> rows) => [
        for (final row in rows)
          BookmarkEntry(
            ayah: row.readTable(_db.ayahs),
            bookmarkId: row.readTable(_db.bookmarks).id,
          ),
      ];
}
