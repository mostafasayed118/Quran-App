/// Persisted reader display preferences.
abstract interface class ReaderSettingsSource {
  /// The saved font scale; 1.0 when unset or malformed.
  Future<double> loadFontScale();

  /// Persists [scale], clamped by the implementation.
  Future<void> saveFontScale(double scale);
}
