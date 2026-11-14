/// Icon sizes by role.
///
/// The tree had ten sizes for twenty-seven icons. The recurring ones get a
/// scale; the one-off screen marks keep a named role instead of a bare number,
/// so the next screen can see what already exists. Every value is one already
/// shipping, so adopting a token never changes a painted pixel.
abstract final class AppIconSize {
  /// Dense inline meta glyph (the home location pin).
  static const double inline = 13;

  /// Status dot (the tracker's last-seven-days row).
  static const double dot = 14;

  /// Compact row action (backup, countdown header, folder chips).
  static const double sm = 16;

  /// Default list and tile glyph.
  static const double md = 18;

  /// Prominent row glyph or a selection check.
  static const double lg = 20;

  /// Tile badge glyph.
  static const double xl = 22;

  /// Empty or error state mark.
  static const double state = 40;

  /// Screen-header mark (the next-prayer countdown).
  static const double hero = 48;

  /// Qibla needle.
  static const double dial = 72;

  /// Blocking update gate mark.
  static const double gate = 84;
}
