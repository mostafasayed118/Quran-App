import 'package:flutter/widgets.dart';

import '../layout/app_breakpoints.dart';

/// Caps a screen body at a readable measure and centres it on wide windows.
///
/// Below [maxWidth] the child is returned untouched, so phone layout and
/// every phone-sized widget test keep their exact geometry. Above it the body
/// keeps its full height (scroll views and `Column + Expanded` still expand)
/// and is centred horizontally with equal margins.
class AppContentFrame extends StatelessWidget {
  /// Creates the frame; [maxWidth] defaults to the content measure.
  const AppContentFrame({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  /// Long-form reading (reader, hadith): the narrowest measure.
  const AppContentFrame.reading({super.key, required this.child})
      : maxWidth = AppBreakpoints.readingMaxWidth;

  /// Narrow forms: onboarding, zakat, prayer settings.
  const AppContentFrame.form({super.key, required this.child})
      : maxWidth = AppBreakpoints.formMaxWidth;

  /// Grids: the widest measure before they read as a stretched phone.
  const AppContentFrame.grid({super.key, required this.child})
      : maxWidth = AppBreakpoints.gridMaxWidth;

  /// The body to constrain.
  final Widget child;

  /// The widest the body may grow, in logical pixels.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= maxWidth) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
