import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

import 'support/theme_snapshot.dart';

Map<String, Color> _roles(ThemeData theme) {
  final scheme = theme.colorScheme;
  return {
    'primary': scheme.primary,
    'onPrimary': scheme.onPrimary,
    'secondary': scheme.secondary,
    'onSecondary': scheme.onSecondary,
    'surface': scheme.surface,
    'onSurface': scheme.onSurface,
    'onSurfaceVariant': scheme.onSurfaceVariant,
    'primaryContainer': scheme.primaryContainer,
    'onPrimaryContainer': scheme.onPrimaryContainer,
    'secondaryContainer': scheme.secondaryContainer,
    'onSecondaryContainer': scheme.onSecondaryContainer,
    'surfaceContainerHighest': scheme.surfaceContainerHighest,
    'outline': scheme.outline,
    'error': scheme.error,
    'errorContainer': scheme.errorContainer,
    'surfaceTint': scheme.surfaceTint,
    'onError': scheme.onError,
    'onErrorContainer': scheme.onErrorContainer,
    'inverseSurface': scheme.inverseSurface,
    'onInverseSurface': scheme.onInverseSurface,
    'surfaceContainerLowest': scheme.surfaceContainerLowest,
    'surfaceContainerLow': scheme.surfaceContainerLow,
    'surfaceContainerHigh': scheme.surfaceContainerHigh,
    'outlineVariant': scheme.outlineVariant,
    'appBarBackground': theme.appBarTheme.backgroundColor!,
    'appBarForeground': theme.appBarTheme.foregroundColor!,
    'scaffoldBackground': theme.scaffoldBackgroundColor,
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
