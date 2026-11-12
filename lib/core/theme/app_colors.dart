import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primaryBeige = Color(0xFFF1EAD7);
  static const beigeSurface = Color(0xFFE7DECB);
  static const emerald = Color(0xFF3E6B58);
  static const emeraldDark = Color(0xFF2E5244);
  static const emeraldLight = Color(0xFFE4EEE9);
  static const gold = Color(0xFFE3A53E);

  /// The light-theme `secondary`. [gold] is a light accent: used as a state
  /// colour on the cream surfaces it measures 1.7–2.1:1, below the 3:1 floor
  /// for meaningful graphics. This keeps the hue and clears 3:1 on the card,
  /// the page and the tiles (4.0 / 3.4 / 3.2 measured 2026-11-13).
  static const goldStrong = Color(0xFFB06F18);
  static const goldText = Color(0xFF8A5A14);
  static const goldLight = Color(0xFFF7EAD2);
  static const pageBackground = Color(0xFFEFE9DA);
  static const ink = Color(0xFF232D28);
  static const hairline = Color(0xFFD9D2BF);
  static const cardBackground = Color(0xFFFFFDF7);

  static const darkSurface = Color(0xFF16201B);
  static const darkOnSurface = Color(0xFFE8E2D2);
  static const darkBackground = Color(0xFF101410);
  static const darkHairline = Color(0xFF2A362F);

  /// Highlight surface for "the one row that matters" (next prayer, active
  /// dhikr, today's hijri day).
  ///
  /// Declared explicitly instead of letting `ColorScheme.fromSeed` invent it:
  /// the generated value was a saturated mint that read as a different app
  /// against the ivory page.
  static const emeraldTintLight = Color(0xFFDCE8E1);
  static const onEmeraldTintLight = Color(0xFF1E3A30);
  static const emeraldTintDark = Color(0xFF1E2F27);
  static const onEmeraldTintDark = Color(0xFFD7E7DD);

  /// Quiet grouping surface for grids and inset panels.
  static const tileLight = Color(0xFFE6E2D4);
  static const tileDark = Color(0xFF1A251F);

  /// The mushaf verse card's own palette.
  ///
  /// Deliberately dark in both themes: the card is the reader's "parchment"
  /// surface and its identity does not follow the app chrome. Declared here
  /// so the reader holds no raw `Color(0x…)` literals of its own — a theme
  /// change reaches them through this one file.
  static const mushafCardTop = Color(0xFF0B2E24);
  static const mushafCardBottom = Color(0xFF144233);
  static const mushafCardInk = Color(0xFFF4E6C3);
  static const mushafCardAccent = Color(0xFFD9B45B);
  static const mushafCardMuted = Color(0xFFB9C9C0);

  static const double badgeTintAlpha = 0.12;
  static const double fieldTintAlpha = 0.08;
  static const double mutedSurfaceAlpha = 0.5;
  static const double scrimAlpha = 0.32;
}
