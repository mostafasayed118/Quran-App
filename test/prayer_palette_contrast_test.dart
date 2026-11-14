import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/theme/prayer_palette.dart';

/// The AA floor for text; graphics (icons, ornaments, large text) use 3.0.
const double _text = 4.5;
const double _graphics = 3.0;

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void expectAtLeast(
    Color foreground, Color background, double floor, String label) {
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
      final palette = PrayerPalettes.of(name, brightness);
      final label = '${name.name}/${brightness.name}';

      test('$label clears the text floors', () {
        expectAtLeast(palette.ink, palette.page, _text, '$label ink/page');
        expectAtLeast(
            palette.ink, palette.surface, _text, '$label ink/surface');
        expectAtLeast(
            palette.muted, palette.surface, _text, '$label muted/surface');
        expectAtLeast(palette.onPrimary, palette.primary, _text,
            '$label onPrimary/primary');
        expectAtLeast(
            palette.onTint, palette.tint, _text, '$label onTint/tint');
        expectAtLeast(
            palette.primary, palette.surface, _text, '$label primary/surface');
        expectAtLeast(palette.goldText, palette.surface, _text,
            '$label goldText/surface');
        expectAtLeast(palette.ink, palette.appBar, _text, '$label ink/appBar');
      });

      test('$label clears the container floors', () {
        expectAtLeast(
          palette.onSecondaryContainer,
          palette.secondaryContainer,
          _text,
          '$label onSecondaryContainer',
        );
        expectAtLeast(
          palette.onErrorContainer,
          palette.errorContainer,
          _text,
          '$label onErrorContainer',
        );
      });

      test('$label clears the graphics floors', () {
        expectAtLeast(
            palette.gold, palette.surface, _graphics, '$label gold/surface');
        expectAtLeast(
            palette.onGold, palette.gold, _graphics, '$label onGold/gold');
        for (final entry in {
          'success': palette.success,
          'warning': palette.warning,
          'error': palette.error,
          'info': palette.info,
        }.entries) {
          expectAtLeast(entry.value, palette.surface, _text,
              '$label ${entry.key}/surface');
        }
      });
    }
  }
}
