// Compat: existing importers of this file keep resolving [BookmarkMetaEntry],
// which now lives in domain/ so presentation stays off the data layer.
import '../domain/bookmark_meta.dart';

export '../domain/bookmark_meta.dart';

/// The persisted bookmark metadata store.
abstract interface class BookmarkMetaSource {
  /// Every stored entry, keyed by ayah id; empty when unset or malformed.
  Future<Map<int, BookmarkMetaEntry>> load();

  /// Persists [entries]; empty entries are dropped by the implementation.
  Future<void> save(Map<int, BookmarkMetaEntry> entries);
}

/// Drops [ayahId]'s folder/note, if it has one.
///
/// A folder or note describes a bookmark; when the bookmark goes away the
/// metadata must go with it, otherwise the folder chip and its screen outlive
/// the bookmark and re-bookmarking silently resurrects stale data.
Future<void> removeBookmarkMeta(BookmarkMetaSource source, int ayahId) async {
  final entries = await source.load();
  if (entries.remove(ayahId) == null) return;
  await source.save(entries);
}
