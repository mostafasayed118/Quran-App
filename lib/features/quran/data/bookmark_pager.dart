import '../../../core/db/app_database.dart';

/// One readable bookmark row: the bookmark joined with its ayah.
class BookmarkEntry {
  /// A bookmark together with the ayah it points at.
  const BookmarkEntry({required this.ayah, this.bookmarkId = 0});

  /// The bookmarked ayah.
  final Ayah ayah;

  /// Row id of the bookmark itself — the paging cursor. 0 for rows built by
  /// hand in tests.
  final int bookmarkId;
}

/// One page of bookmarks, newest first.
class BookmarkPage {
  const BookmarkPage({required this.entries, required this.hasMore});

  final List<BookmarkEntry> entries;
  final bool hasMore;
}

/// Default page size for the bookmarks list.
const int kBookmarkPageSize = 20;

/// Keyset paging over the bookmark list, ordered by bookmark id descending.
///
/// Kept separate from `AyahSource` on purpose: the reader seam is frozen and
/// three test doubles implement it, so paging is an opt-in capability.
abstract class BookmarkPager {
  /// Live first page (newest bookmarks); re-emits on every bookmark change.
  Stream<BookmarkPage> watchFirstPage({int limit = kBookmarkPageSize});

  /// Older page strictly below [beforeBookmarkId].
  Future<BookmarkPage> entriesBefore(
    int beforeBookmarkId, {
    int limit = kBookmarkPageSize,
  });
}
