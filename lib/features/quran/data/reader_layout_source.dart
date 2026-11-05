/// Persisted reader layout preferences.
///
/// Separated from [ReaderSettingsSource] on purpose: the font scale is the
/// original contract with frozen test doubles, and Dart's `implements` does
/// not inherit method bodies. A second interface keeps every existing double
/// compiling while the repository implements both.
abstract interface class ReaderLayoutSource {
  /// The historical line height of the verse and mushaf text.
  static const double defaultLineHeight = 2.2;

  /// The narrowest and widest line height the reader accepts.
  static const double minLineHeight = 1.6;
  static const double maxLineHeight = 3.0;

  /// The saved line-height multiplier; [defaultLineHeight] when unset or
  /// malformed.
  Future<double> loadLineHeight();

  /// Persists [lineHeight], clamped by the implementation.
  Future<void> saveLineHeight(double lineHeight);
}
