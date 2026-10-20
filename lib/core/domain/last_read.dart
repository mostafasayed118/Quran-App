/// Cross-feature seam for the last-read marker (the home screen's
/// "continue reading" card reads it without importing the quran feature).
abstract interface class LastReadMarker {
  /// The ayah id the reader last showed; null while nothing was read.
  Future<int?> loadAyahId();
}
