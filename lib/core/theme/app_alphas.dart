/// Opacity roles for tints, rules and muted ink.
///
/// Named by the role they play, never by the value: a chip fill ([chipTint])
/// and a divider on a tinted container ([dividerOnTint]) stay separate tokens
/// even though 0.10 and 0.12 are close, because merging them would be a silent
/// visual change. Every value below is one already shipping, so adopting a
/// token never moves a pixel on its own.
///
/// [metaInk] (0.70) and [secondaryInk] (0.75) are two shipped values for an
/// apparently similar role. Unifying them is a reading decision with
/// before/after screenshots, not part of this mechanical pass.
abstract final class AppAlphas {
  /// Fill behind a small icon chip on a card (primary at 10%).
  static const double chipTint = 0.10;

  /// Hairline divider drawn on a tinted container (onPrimaryContainer at 12%).
  static const double dividerOnTint = 0.12;

  /// Faint outline around a tinted card (primary at 18%).
  static const double outlineFaint = 0.18;

  /// Quiet tile behind a secondary control (secondary at 14%).
  static const double secondaryTile = 0.14;

  /// Error wash behind the qibla dial (errorContainer at 35%).
  static const double errorTint = 0.35;

  /// The verse card's accent rule (mushaf accent at 35%).
  static const double accentRule = 0.35;

  /// The softer inner rule under the verse (mushaf accent at 25%).
  static const double accentRuleSoft = 0.25;

  /// Inline meta ink on a tinted card: location and city (0.70).
  static const double metaInk = 0.70;

  /// Secondary line ink on a tinted container (0.75).
  static const double secondaryInk = 0.75;

  /// A trailing glyph that supports a row without competing with it (0.60).
  static const double iconMuted = 0.60;

  /// Child opacity for a completed dhikr row (0.80); 1 is fully opaque.
  static const double completedFade = 0.80;
}
