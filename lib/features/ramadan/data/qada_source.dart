/// Persisted qada (missed fast) dates.
abstract interface class QadaSource {
  /// The recorded dates, normalized to date-only and sorted; empty when
  /// unset or malformed.
  Future<List<DateTime>> loadMissed();

  /// Persists [dates] after normalizing them.
  Future<void> saveMissed(List<DateTime> dates);
}
