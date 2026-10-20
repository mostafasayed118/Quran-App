/// Spacing scale shared by the presentation layer.
///
/// The values are the ones already used across the app, so adopting a token
/// instead of a literal never changes a rendered pixel — it only makes the
/// rhythm explicit and greppable.
///
/// Step by 4, with the mid steps left out on purpose: a gap that is not on
/// the scale stays a literal until the design says otherwise.
abstract final class AppSpacing {
  /// Tightest gap: hairline separation between a label and its value.
  static const double xs = 4;

  /// Default gap between related elements (icon + caption, chip + chip).
  static const double sm = 8;

  /// Default padding inside a card or a list row.
  static const double md = 12;

  /// Outer padding of a screen section.
  static const double lg = 16;

  /// Breathing room between two sections.
  static const double xl = 24;
}
