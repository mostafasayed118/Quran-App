import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pins the reading stack to the shipped theme.
///
/// The prayer skin recolours the **chrome** only. The reader, the mushaf page
/// and the sheets they open must stay identical whatever the period is, so
/// this wrapper replaces the palette theme with the shipped one for its
/// subtree. Brightness is not a palette decision, so it still follows the
/// device.
class NeutralReadingTheme extends StatelessWidget {
  /// Wraps [child] in the shipped light or dark theme.
  const NeutralReadingTheme({super.key, required this.child});

  /// The reading subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: isDark ? AppTheme.dark : AppTheme.light,
      child: child,
    );
  }
}
