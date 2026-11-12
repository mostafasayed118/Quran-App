import 'package:flutter/widgets.dart';

/// Width classes and content measures for the responsive layout.
///
/// Three classes, following the Material 3 window-size breakpoints:
/// compact (< 600), medium (600–839) and expanded (≥ 840). The shell only
/// switches to a navigation rail at [expanded] on purpose: medium keeps the
/// bottom bar, which is an allowed M3 choice and keeps the existing 800-wide
/// shell test pin intact.
abstract final class AppBreakpoints {
  /// Start of the medium window class.
  static const double medium = 600;

  /// Start of the expanded window class (navigation rail, widest content).
  static const double expanded = 840;

  /// The longest line a reader should have to track, in logical pixels.
  ///
  /// A tablet renders a phone-width column of text instead of a 1000 dp line.
  static const double readingMaxWidth = 760;

  /// Forms, settings and list-detail content.
  static const double contentMaxWidth = 720;

  /// A narrow form: onboarding, zakat, prayer settings.
  static const double formMaxWidth = 640;

  /// The list-detail master pane on an expanded window.
  static const double masterWidth = 340;

  /// The master pane below [expanded], where the detail pane needs more room.
  static const double compactMasterWidth = 300;

  /// Grids may use more width before they read as a stretched phone.
  static const double gridMaxWidth = 1000;

  /// Modal sheets stop widening past this; below it they fill the screen.
  static const double sheetMaxWidth = 640;

  /// Whether the app is in the expanded window class.
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}
