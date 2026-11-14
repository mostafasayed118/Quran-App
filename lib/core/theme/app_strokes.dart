/// Border widths by role.
///
/// Only the widths that carry a meaning are tokens: the default hairline is
/// Flutter's own 1.0 and stays implicit. Values are the ones already shipping.
abstract final class AppStrokes {
  /// Field and today-cell emphasis.
  static const double emphasis = 1.4;

  /// Selection ring around a chosen reciter.
  static const double selection = 1.5;

  /// Decorative ring on the splash frames.
  static const double ring = 1.6;

  /// The accent bar that marks the next prayer and the tasbih ring.
  static const double accent = 3;
}
