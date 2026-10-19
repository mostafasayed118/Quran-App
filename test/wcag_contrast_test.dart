import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/wcag_contrast.dart';

void main() {
  const cardBackground = 0xFFFDF7;
  const pageBackground = 0xEFE9DA;
  const primaryBeige = 0xF1EAD7;
  const darkScaffold = 0x101410;
  const darkSurface = 0x16201B;
  const lightSurfaces = [cardBackground, pageBackground, primaryBeige];
  const darkSurfaces = [darkScaffold, darkSurface];

  int of(int c) => c | 0xFF000000;
  double ratioOf(int tone, int surface) =>
      wcagContrastRatio(of(tone), of(surface));

  test('goldText tone clears AA (4.5:1) on every light surface', () {
    expect(AppColors.goldText, const Color(0xFF8A5A14));
    for (final surface in lightSurfaces) {
      expect(
        ratioOf(AppColors.goldText.toARGB32(), surface),
        greaterThanOrEqualTo(4.5),
        reason: 'goldText on 0x${surface.toRadixString(16)}',
      );
    }
  });

  test('existing gold keeps AA on the dark-mode surfaces', () {
    for (final surface in darkSurfaces) {
      expect(
        ratioOf(AppColors.gold.toARGB32(), surface),
        greaterThanOrEqualTo(4.5),
        reason: 'gold on 0x${surface.toRadixString(16)}',
      );
    }
  });

  test('raw gold as text on light surfaces fails AA (audited ~2:1 defect)', () {
    expect(
      ratioOf(AppColors.gold.toARGB32(), cardBackground),
      lessThan(4.5),
    );
    expect(
      ratioOf(AppColors.gold.toARGB32(), pageBackground),
      lessThan(4.5),
    );
  });

  test('both tones clear the 3:1 large-text bar on their mode surfaces', () {
    for (final surface in lightSurfaces) {
      expect(
        ratioOf(AppColors.goldText.toARGB32(), surface),
        greaterThanOrEqualTo(3.0),
      );
    }
    for (final surface in darkSurfaces) {
      expect(
        ratioOf(AppColors.gold.toARGB32(), surface),
        greaterThanOrEqualTo(3.0),
      );
    }
  });

  test('helper sanity: identical colors give a ratio of exactly 1', () {
    expect(
        wcagContrastRatio(of(0xE3A53E), of(0xE3A53E)), moreOrLessEquals(1.0));
  });
}
