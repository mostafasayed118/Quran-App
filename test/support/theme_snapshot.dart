import 'package:flutter/material.dart';

/// The shipped theme's roles, captured on `684ab3d9` **before** the prayer-skin
/// work (the printer test was deleted after this file was written).
///
/// One intended delta: `light.onSecondary` becomes `0xFFFFFDF7` in W0.2 (white
/// on the light gold, 3.47 -> 5.0). Every other value must stay identical.
const Map<String, Map<String, Color>> shippedThemeRoles = {
  'light': {
    'primary': Color(0xFF3E6B58),
    'onPrimary': Color(0xFFFFFDF7),
    'secondary': Color(0xFFB06F18),
    // intended delta (W0.2): white on the light gold, 3.47 -> 5.0.
    'onSecondary': Color(0xFFFFFDF7),
    'surface': Color(0xFFFFFDF7),
    'onSurface': Color(0xFF232D28),
    'onSurfaceVariant': Color(0xFF404944),
    'primaryContainer': Color(0xFFDCE8E1),
    'onPrimaryContainer': Color(0xFF1E3A30),
    'secondaryContainer': Color(0xFFF7EAD2),
    'onSecondaryContainer': Color(0xFF8A5A14),
    'surfaceContainerHighest': Color(0xFFE6E2D4),
    'outline': Color(0xFF707973),
    'error': Color(0xFFBA1A1A),
    'errorContainer': Color(0xFFFFDAD6),
    'surfaceTint': Color(0xFF1C6B50),
    'appBarBackground': Color(0xFFF1EAD7),
    'appBarForeground': Color(0xFF2E5244),
    'scaffoldBackground': Color(0xFFEFE9DA),
  },
  'dark': {
    'primary': Color(0xFFE4EEE9),
    'onPrimary': Color(0xFF232D28),
    'secondary': Color(0xFFE3A53E),
    'onSecondary': Color(0xFF232D28),
    'surface': Color(0xFF16201B),
    'onSurface': Color(0xFFE8E2D2),
    'onSurfaceVariant': Color(0xFFBFC9C2),
    'primaryContainer': Color(0xFF1E2F27),
    'onPrimaryContainer': Color(0xFFD7E7DD),
    'secondaryContainer': Color(0xFFF7EAD2),
    'onSecondaryContainer': Color(0xFF8A5A14),
    'surfaceContainerHighest': Color(0xFF1A251F),
    'outline': Color(0xFF89938D),
    'error': Color(0xFFFFB4AB),
    'errorContainer': Color(0xFF93000A),
    'surfaceTint': Color(0xFF8BD5B5),
    'appBarBackground': Color(0xFF16201B),
    'appBarForeground': Color(0xFFE8E2D2),
    'scaffoldBackground': Color(0xFF101410),
  },
};
