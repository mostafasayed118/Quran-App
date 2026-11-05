/// Persisted local Hijri correction.
abstract interface class HijriOffsetSource {
  /// The saved correction in days; 0 when unset or malformed.
  Future<int> loadOffsetDays();

  /// Persists [days], clamped to the service's range by the implementation.
  Future<void> saveOffsetDays(int days);
}
