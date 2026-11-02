/// Persisted azkar progress: the counters left on each collection plus the
/// collections the user pinned.
class AzkarSavedState {
  /// Creates a saved state; both fields are empty on a fresh install.
  const AzkarSavedState({
    this.remaining = const <String, List<int>>{},
    this.favorites = const <String>{},
  });

  /// The remaining repetition count per collection id, in item order.
  final Map<String, List<int>> remaining;

  /// The pinned collection ids.
  final Set<String> favorites;
}

/// Storage seam for [AzkarSavedState].
///
/// Deliberately optional in the cubit: the counter works in memory without it,
/// so a failed read or write never blocks reciting.
abstract interface class AzkarSavedStateSource {
  /// Reads the stored state; malformed rows degrade to an empty state.
  Future<AzkarSavedState> load();

  /// Stores the remaining counters of [collectionId].
  Future<void> saveRemaining(String collectionId, List<int> remaining);

  /// Stores the pinned collection ids.
  Future<void> saveFavorites(Set<String> favorites);
}
