import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';

void main() {
  test('the ladder is the twelve agreed rungs', () {
    expect(AppType.ladder, {11, 12, 14, 16, 18, 20, 22, 24, 28, 40, 44, 56});
    expect(AppType.ladder.length, 12);
  });

  test('the component tokens are the four named exceptions', () {
    expect(AppType.componentSizes, {10, 26, 30, 34});
  });

  test('the Quran aliases point at rungs, not new numbers', () {
    expect(AppType.quranMushaf, 22);
    expect(AppType.quranVerse, 24);
    expect(AppType.ayahNumber, 28);
    expect(AppType.ladder, contains(AppType.quranMushaf));
    expect(AppType.ladder, contains(AppType.quranVerse));
    expect(AppType.ladder, contains(AppType.ayahNumber));
  });

  test('the named styles read from the scale', () {
    expect(AppTheme.meQuranHead.fontSize, AppType.titleLarge);
    expect(AppTheme.meQuranTitle.fontSize, AppType.title);
    expect(AppTheme.hafsAyah.fontSize, AppType.quranVerse);
    expect(AppTheme.hafsAyah.height, AppType.quranHeight);
    expect(AppTheme.rowTitle.fontSize, AppType.bodyLarge);
    expect(AppTheme.heroValue.fontSize, AppType.heroValue);
    expect(AppTheme.cardTitle.fontSize, AppType.bodyLarge);
  });

  test('the weights are the two Cairo ships', () {
    expect(AppType.weights, {FontWeight.w400, FontWeight.w700});
  });
}
