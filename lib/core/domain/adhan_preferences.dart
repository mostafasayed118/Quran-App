/// Persisted adhan choices: one global reciter, plus an optional Fajr override.
///
/// The keys are plain strings in the existing settings table rather than a
/// JSON envelope, so a backup stays human-readable and a partial restore is
/// still meaningful. `''` is the storage encoding of "no override" because the
/// settings table has no nullable value column.
const String adhanIdKey = 'adhan_id';
const String adhanFajrIdKey = 'adhan_fajr_id';

/// Cross-feature seam for the adhan selection.
///
/// Both getters normalise: an id that this build does not ship (a backup from
/// a newer version, a reciter removed for rights reasons, a hand-edited file)
/// resolves to the default track or to "no override" instead of propagating a
/// dead id into the notification plan.
abstract interface class AdhanPreferences {
  /// The global adhan id; the default track when unset or unrecognised.
  Future<String> adhanId();

  /// The Fajr override, or null for "same as the global choice".
  Future<String?> fajrAdhanId();

  /// Persists [id] as the global choice.
  Future<void> setAdhanId(String id);

  /// Persists the Fajr override; null clears it back to "same as default".
  Future<void> setFajrAdhanId(String? id);
}
