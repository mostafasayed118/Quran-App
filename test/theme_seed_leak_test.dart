import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/prayer_palette.dart';

/// Guards the palette path against `ColorScheme.fromSeed`.
///
/// Every role the widgets read must come from the period palette. Delete one
/// override in `_theme` and `fromSeed` produces a seeded value here, so the
/// failure names the role instead of showing a wrong colour on a device.
int _hex(Color color) => color.toARGB32();

int _blend(Color foreground, double alpha, Color background) =>
    Color.alphaBlend(foreground.withValues(alpha: alpha), background)
        .toARGB32();

void main() {
  for (final name in PrayerName.values) {
    for (final brightness in Brightness.values) {
      final palette = PrayerPalettes.of(name, brightness);
      final theme = AppTheme.forPrayer(name, brightness);
      final scheme = theme.colorScheme;
      final label = '${name.name}/${brightness.name}';

      test('$label reads only its palette', () {
        expect(_hex(scheme.primary), _hex(palette.primary), reason: 'primary');
        expect(_hex(scheme.onPrimary), _hex(palette.onPrimary),
            reason: 'onPrimary');
        expect(_hex(scheme.secondary), _hex(palette.gold), reason: 'secondary');
        expect(_hex(scheme.onSecondary), _hex(palette.onGold),
            reason: 'onSecondary');
        expect(_hex(scheme.surface), _hex(palette.surface), reason: 'surface');
        expect(_hex(scheme.onSurface), _hex(palette.ink), reason: 'onSurface');
        expect(_hex(scheme.primaryContainer), _hex(palette.tint),
            reason: 'primaryContainer');
        expect(_hex(scheme.onPrimaryContainer), _hex(palette.onTint),
            reason: 'onPrimaryContainer');
        expect(_hex(scheme.onSecondaryContainer), _hex(palette.goldText),
            reason: 'onSecondaryContainer');
        expect(_hex(scheme.surfaceContainerHighest), _hex(palette.tile),
            reason: 'surfaceContainerHighest');
        expect(_hex(scheme.onSurfaceVariant), _hex(palette.muted),
            reason: 'onSurfaceVariant');
        expect(_hex(scheme.outline), _hex(palette.hairline), reason: 'outline');
        expect(_hex(scheme.outlineVariant), _hex(palette.hairline),
            reason: 'outlineVariant');
        expect(_hex(scheme.error), _hex(palette.error), reason: 'error');
      });

      test('$label derives its containers from the tokens', () {
        expect(_hex(scheme.surfaceTint), _hex(palette.primary),
            reason: 'surfaceTint must be the period primary, not the seed');
        expect(
          _hex(scheme.secondaryContainer),
          _blend(palette.gold, 0.14, palette.surface),
          reason: 'secondaryContainer must be a 14% gold wash',
        );
        expect(
          _hex(scheme.errorContainer),
          _blend(palette.error, 0.12, palette.surface),
          reason: 'errorContainer must be a 12% error wash',
        );
        // Retuning `error` has to move the light label with it; a copied hex
        // would freeze the pair and only the contrast test would notice.
        final expectedLabel = brightness == Brightness.light
            ? _blend(Colors.black, 0.22, palette.error)
            : _hex(palette.error);
        expect(_hex(scheme.onErrorContainer), expectedLabel,
            reason: 'onErrorContainer must be derived from error');
      });

      test('$label carries the chrome surfaces', () {
        expect(_hex(theme.scaffoldBackgroundColor), _hex(palette.page),
            reason: 'page');
        expect(_hex(theme.appBarTheme.backgroundColor!),
            _blend(palette.primary, 0.06, palette.page),
            reason: 'appBar is the page tinted 6% toward primary');
        expect(_hex(theme.appBarTheme.foregroundColor!), _hex(palette.ink),
            reason: 'appBarInk');
        expect(_hex(theme.dividerTheme.color!), _hex(palette.hairline),
            reason: 'divider');
        expect(_hex(scheme.surfaceContainer), _hex(palette.surface),
            reason: 'dialog surface');
        expect(_hex(scheme.surfaceContainerLow), _hex(palette.surface),
            reason: 'low sheet surface');
        expect(_hex(scheme.surfaceContainerHigh), _hex(palette.tile),
            reason: 'high sheet surface');
        expect(_hex(scheme.inverseSurface), _hex(palette.ink),
            reason: 'snackbar inverse');
        expect(_hex(scheme.onInverseSurface), _hex(palette.surface),
            reason: 'on snackbar inverse');
        expect(
            _hex(theme.snackBarTheme.actionTextColor!), _hex(palette.goldText),
            reason: 'snackbar action');
        final cardSide =
            (theme.cardTheme.shape! as RoundedRectangleBorder).side;
        expect(_hex(cardSide.color), _hex(palette.hairline),
            reason: 'card hairline');
      });
    }
  }
}
