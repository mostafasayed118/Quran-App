/// Cross-feature seam: the reader records mushaf page progress into the
/// active wird plan through this interface, so the quran feature never
/// imports the tracker feature directly (pinned cross-feature edges stay
/// untouched).
abstract interface class WirdProgressSink {
  /// Advances the plan's read-up-to pointer to [ayahId] when a plan is
  /// active and [ayahId] is ahead of the pointer (max-wins, never backward).
  /// A no-op while no plan is active.
  Future<void> advanceTo(int ayahId);
}
