/// Cross-feature seam for clearing the optional pre-adhan alarm.
///
/// The fixed planner ids are cancelled on every plan; the optional id 4 is not
/// part of that frozen trio, so turning the feature off must clear it
/// explicitly (including after a restart, when the in-memory last-plan set is
/// empty).
abstract interface class PreAdhanCanceller {
  /// Cancels the optional pre-adhan alarm; best-effort, never throws.
  Future<void> cancelPreAdhan();
}
