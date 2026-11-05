/// Persisted hadith bookmarks, per pack.
abstract interface class HadithBookmarkSource {
  /// The saved hadith numbers of [packId]; empty when unset or malformed.
  Future<Set<int>> load(String packId);

  /// Persists the full set for [packId].
  Future<void> save(String packId, Set<int> numbers);
}

/// Persisted last browse offset, per pack.
abstract interface class HadithPositionSource {
  /// The saved offset of [packId]; 0 when unset or malformed.
  Future<int> load(String packId);

  /// Persists [offset] for [packId].
  Future<void> save(String packId, int offset);
}
