import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/prayer_palette.dart';

/// The same WCAG gate as `prayer_palette_contrast_test.dart`, but read from the
/// **built `ThemeData`** instead of the raw palette.
///
/// A removed or wrong override in `_theme` leaves the palette intact while the
/// screen shows the seeded value; this file is what catches that. The four
/// semantic tones (success/warning/error/info on surface) stay palette-only:
/// three of them have no `ColorScheme` role.
const double _text = 4.5;
const double _graphics = 3.0;

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _atLeast(Color foreground, Color background, double floor, String label) {
  final ratio = _ratio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(floor),
    reason: '$label is ${ratio.toStringAsFixed(2)}:1',
  );
}

void main() {
  for (final name in PrayerName.values) {
    for (final brightness in Brightness.values) {
      final label = '${name.name}/${brightness.name}';
      final theme = AppTheme.forPrayer(name, brightness);
      final colors = theme.colorScheme;
      final page = theme.scaffoldBackgroundColor;
      final appBar = theme.appBarTheme.backgroundColor!;

      test('$label: the built ThemeData clears the text floors', () {
        _atLeast(colors.onSurface, page, _text, '$label onSurface/page');
        _atLeast(colors.onSurface, colors.surface, _text,
            '$label onSurface/surface');
        _atLeast(colors.onSurfaceVariant, colors.surface, _text,
            '$label onSurfaceVariant');
        _atLeast(colors.onPrimary, colors.primary, _text, '$label onPrimary');
        _atLeast(colors.onPrimaryContainer, colors.primaryContainer, _text,
            '$label onPrimaryContainer');
        _atLeast(
            colors.primary, colors.surface, _text, '$label primary/surface');
        _atLeast(colors.onSecondaryContainer, colors.surface, _text,
            '$label goldText/surface');
        _atLeast(colors.onSurface, appBar, _text, '$label onSurface/appBar');
      });

      test('$label: the built ThemeData clears the container floors', () {
        _atLeast(colors.onSecondaryContainer, colors.secondaryContainer, _text,
            '$label onSecondaryContainer/secondaryContainer');
        _atLeast(colors.onErrorContainer, colors.errorContainer, _text,
            '$label onErrorContainer/errorContainer');
      });

      test('$label: the built ThemeData clears the graphics floors', () {
        _atLeast(
            colors.secondary, colors.surface, _graphics, '$label gold/surface');
        _atLeast(colors.onSecondary, colors.secondary, _graphics,
            '$label onGold/gold');
        final palette = PrayerPalettes.of(name, brightness);
        for (final entry in {
          'success': palette.success,
          'warning': palette.warning,
          'error': colors.error,
          'info': palette.info,
        }.entries) {
          _atLeast(entry.value, colors.surface, _text,
              '$label ${entry.key}/surface');
        }
      });

      test('$label: the built ThemeData separates a sheet from a card', () {
        expect(colors.surfaceContainerLow, isNot(colors.surface));
        final ratio = _ratio(colors.surfaceContainerLow, colors.surface);
        expect(
          ratio,
          greaterThan(1.06),
          reason: '$label sheet/card is ${ratio.toStringAsFixed(3)}:1',
        );
      });
    }
  }
}
