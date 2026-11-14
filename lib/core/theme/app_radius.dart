/// Corner-radius scale for the presentation layer.
///
/// Before this file the app carried five different radii chosen per screen
/// (10, 11, 12, 14, 16, 28), so two adjacent surfaces could disagree about
/// how round "a card" is. Every new surface picks a step from here; the
/// values are the ones already shipping, so adopting a token never changes a
/// rendered pixel on its own.
library;

import 'package:flutter/painting.dart';

abstract final class AppRadius {
  /// Chips, inline tags, small controls.
  static const double sm = 8;

  /// Inputs and compact surfaces (search field).
  static const double md = 12;

  /// Standard card and list-row surface.
  static const double lg = 16;

  /// Grouping panel and modal sheet.
  static const double xl = 24;

  /// Fully round: pills, badges, toggle-shaped buttons.
  static const double pill = 999;

  /// Inset panel and input surface (14).
  ///
  /// A shipped component value, not a new rung: the asma tiles and the zakat
  /// field use it. W2 candidate to fold into [lg].
  static const double panel = 14;

  /// Hijri day cell (10). W2 candidate to fold into [md].
  static const double dayCell = 10;

  /// Reciter selection check (11). W2 candidate to fold into [md].
  static const double selection = 11;

  /// Bottom-sheet top corners (28). Matches the modal sheet's shipped shape.
  static const double sheet = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
