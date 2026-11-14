import 'package:flutter/material.dart';

/// Every `ColorScheme` (and two `ThemeData`) role the app reads, as ARGB ints.
///
/// Ints, not `Color`s: `Color.alphaBlend` keeps float channels, so comparing
/// `Color` objects fails by a rounding fraction even when the hex is right.
Map<String, int> themeRoles(ThemeData theme) {
  final scheme = theme.colorScheme;
  int hex(Color color) => color.toARGB32();
  return {
    'primary': hex(scheme.primary),
    'onPrimary': hex(scheme.onPrimary),
    'secondary': hex(scheme.secondary),
    'onSecondary': hex(scheme.onSecondary),
    'surface': hex(scheme.surface),
    'onSurface': hex(scheme.onSurface),
    'onSurfaceVariant': hex(scheme.onSurfaceVariant),
    'primaryContainer': hex(scheme.primaryContainer),
    'onPrimaryContainer': hex(scheme.onPrimaryContainer),
    'secondaryContainer': hex(scheme.secondaryContainer),
    'onSecondaryContainer': hex(scheme.onSecondaryContainer),
    'surfaceContainerHighest': hex(scheme.surfaceContainerHighest),
    'outline': hex(scheme.outline),
    'error': hex(scheme.error),
    'errorContainer': hex(scheme.errorContainer),
    'surfaceTint': hex(scheme.surfaceTint),
    'onError': hex(scheme.onError),
    'onErrorContainer': hex(scheme.onErrorContainer),
    'inverseSurface': hex(scheme.inverseSurface),
    'onInverseSurface': hex(scheme.onInverseSurface),
    'surfaceContainerLowest': hex(scheme.surfaceContainerLowest),
    'surfaceContainerLow': hex(scheme.surfaceContainerLow),
    'surfaceContainerHigh': hex(scheme.surfaceContainerHigh),
    'outlineVariant': hex(scheme.outlineVariant),
    'appBarBackground': hex(theme.appBarTheme.backgroundColor!),
    'appBarForeground': hex(theme.appBarTheme.foregroundColor!),
    'scaffoldBackground': hex(theme.scaffoldBackgroundColor),
  };
}
