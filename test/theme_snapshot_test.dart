import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

import 'support/theme_snapshot.dart';

Map<String, int> _roles(ThemeData theme) {
  final scheme = theme.colorScheme;
  int hex(Color c) => c.toARGB32();
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

void main() {
  test('the shipped light theme keeps every role', () {
    expect(_roles(AppTheme.light), shippedThemeRoles['light']);
  });

  test('the shipped dark theme keeps every role', () {
    expect(_roles(AppTheme.dark), shippedThemeRoles['dark']);
  });
}
