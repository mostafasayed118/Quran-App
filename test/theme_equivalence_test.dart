import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

import 'support/theme_roles.dart';
import 'support/theme_snapshot.dart';

void main() {
  // The rollback contract: `fixed` is the default, so the shipped path must
  // stay exactly what the fixture pinned (with the two intended W0 deltas).
  test('the shipped light theme equals the snapshot', () {
    expect(themeRoles(AppTheme.light), shippedThemeRoles['light']);
  });

  test('the shipped dark theme equals the snapshot', () {
    expect(themeRoles(AppTheme.dark), shippedThemeRoles['dark']);
  });

  // `_theme` now takes an optional palette. Building all twelve must not leak
  // into the cached shipped themes (shared statics, `fromSeed` state, …).
  test('building every palette leaves the shipped themes untouched', () {
    AppTheme.clearPrayerCache();
    for (final brightness in Brightness.values) {
      for (final name in PrayerName.values) {
        AppTheme.forPrayer(name, brightness);
      }
    }
    expect(themeRoles(AppTheme.light), shippedThemeRoles['light']);
    expect(themeRoles(AppTheme.dark), shippedThemeRoles['dark']);
  });

  test('every palette actually changes the chrome', () {
    for (final brightness in Brightness.values) {
      for (final name in PrayerName.values) {
        expect(
          themeRoles(AppTheme.forPrayer(name, brightness)),
          isNot(shippedThemeRoles[brightness.name]),
          reason: '${name.name}/${brightness.name} fell back to the seed',
        );
      }
    }
  });

  test('the per-period cache returns one instance and rebuilds after clear',
      () {
    AppTheme.clearPrayerCache();
    final first = AppTheme.forPrayer(PrayerName.fajr, Brightness.light);
    final again = AppTheme.forPrayer(PrayerName.fajr, Brightness.light);
    expect(identical(first, again), isTrue);

    AppTheme.clearPrayerCache();
    final rebuilt = AppTheme.forPrayer(PrayerName.fajr, Brightness.light);
    expect(identical(first, rebuilt), isFalse);
    expect(themeRoles(rebuilt), themeRoles(first));
  });
}
