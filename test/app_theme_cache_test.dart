import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

// The root `build` in lib/app/app.dart reads both AppTheme.light and
// AppTheme.dark on every rebuild. `_theme` runs ColorScheme.fromSeed plus a
// full ThemeData construction, so each read must return the same cached
// instance rather than recomputing the palette.
void main() {
  test('light theme getter returns one cached instance', () {
    expect(identical(AppTheme.light, AppTheme.light), isTrue);
  });

  test('dark theme getter returns one cached instance', () {
    expect(identical(AppTheme.dark, AppTheme.dark), isTrue);
  });

  test('cached light and dark themes are distinct instances', () {
    expect(identical(AppTheme.light, AppTheme.dark), isFalse);
  });

  test('cached themes keep their brightness and seeded primary', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);

    expect(AppTheme.light.colorScheme.primary, AppColors.emerald);
    expect(AppTheme.dark.colorScheme.primary, AppColors.emeraldLight);
  });
}
