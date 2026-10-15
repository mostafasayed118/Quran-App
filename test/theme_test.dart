import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

void main() {
  test('D6 palette tokens match spec', () {
    expect(AppColors.primaryBeige, const Color(0xFFF1EAD7));
    expect(AppColors.beigeSurface, const Color(0xFFE7DECB));
    expect(AppColors.emerald, const Color(0xFF3E6B58));
    expect(AppColors.emeraldDark, const Color(0xFF2E5244));
    expect(AppColors.emeraldLight, const Color(0xFFE4EEE9));
    expect(AppColors.gold, const Color(0xFFE3A53E));
    expect(AppColors.goldLight, const Color(0xFFF7EAD2));
    expect(AppColors.pageBackground, const Color(0xFFEFE9DA));
    expect(AppColors.ink, const Color(0xFF232D28));
  });

  test('light and dark themes differ in brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('font family constants', () {
    expect(QuranFonts.quran, 'HafsSmart');
    expect(QuranFonts.meQuran, 'me_quran');
    expect(QuranFonts.ui, 'Cairo');
  });
}
