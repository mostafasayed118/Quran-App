// Compat: existing importers of this file keep resolving [BookmarkMetaEntry],
// which now lives in domain/ so presentation stays off the data layer.
export '../domain/bookmark_meta.dart';
import '../domain/bookmark_meta.dart';

/// The persisted bookmark metadata store.
abstract interface class BookmarkMetaSource {
  /// Every stored entry, keyed by ayah id; empty when unset or malformed.
  Future<Map<int, BookmarkMetaEntry>> load();

  /// Persists [entries]; empty entries are dropped by the implementation.
  Future<void> save(Map<int, BookmarkMetaEntry> entries);
}
