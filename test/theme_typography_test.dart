import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';

/// The app's typography contract.
///
/// Cairo ships two weights (400 and 700 — see `pubspec.yaml`), so a style that
/// asks for 500/600 renders as 400 while reading as "medium" in source. That
/// gap is how the app ended up with a hierarchy that existed only in code.
void main() {
  const roles = <String>[
    'displayLarge',
    'displayMedium',
    'displaySmall',
    'headlineLarge',
    'headlineMedium',
    'headlineSmall',
    'titleLarge',
    'titleMedium',
    'titleSmall',
    'bodyLarge',
    'bodyMedium',
    'bodySmall',
    'labelLarge',
    'labelMedium',
    'labelSmall',
  ];

  test('every type role is Cairo at one of the two weights the font ships', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      for (final role in roles) {
        final style = theme.textTheme;
        final text = switch (role) {
          'displayLarge' => style.displayLarge,
          'displayMedium' => style.displayMedium,
          'displaySmall' => style.displaySmall,
          'headlineLarge' => style.headlineLarge,
          'headlineMedium' => style.headlineMedium,
          'headlineSmall' => style.headlineSmall,
          'titleLarge' => style.titleLarge,
          'titleMedium' => style.titleMedium,
          'titleSmall' => style.titleSmall,
          'bodyLarge' => style.bodyLarge,
          'bodyMedium' => style.bodyMedium,
          'bodySmall' => style.bodySmall,
          'labelLarge' => style.labelLarge,
          'labelMedium' => style.labelMedium,
          _ => style.labelSmall,
        };
        expect(text, isNotNull, reason: '$role must be defined');
        expect(text!.fontFamily, 'Cairo', reason: '$role family');
        // A null weight renders as w400, which is one of the two weights the
        // bundled Cairo actually has.
        expect(
          text.fontWeight ?? FontWeight.w400,
          anyOf(FontWeight.w400, FontWeight.w700),
          reason: '$role weight',
        );
      }
    }
  });

  test('no source file asks Cairo for a weight it cannot render', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('FontWeight.w500') ||
          source.contains('FontWeight.w600')) {
        hits.add(entity.path);
      }
    }
    expect(hits, isEmpty,
        reason: 'use w400/w700, or change the bundled Cairo weights first');
  });
}
