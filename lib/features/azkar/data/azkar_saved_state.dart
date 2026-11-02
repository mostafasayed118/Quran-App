/// Persisted azkar progress: the counters left on each collection, the day
/// they belong to, and the collections the user pinned.
class AzkarSavedState {
  /// Creates a saved state; both fields are empty on a fresh install.
  const AzkarSavedState({
    this.day = '',
    this.remaining = const <String, List<int>>{},
    this.favorites = const <String>{},
  });

  /// The local day the counters belong to (`yyyy-MM-dd`); '' when unknown.
  ///
  /// Morning and evening azkar are recited daily, so counters stored on an
  /// earlier day are treated as finished-session leftovers, not as progress.
  final String day;

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

  /// Stores the remaining counters of [collectionId] for [day].
  Future<void> saveRemaining(
      String collectionId, List<int> remaining, String day);

  /// Stores the pinned collection ids.
  Future<void> saveFavorites(Set<String> favorites);
}
