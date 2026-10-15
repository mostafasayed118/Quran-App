import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class QuranFonts {
  static const quran = 'HafsSmart';
  static const meQuran = 'me_quran';
  static const ui = 'Cairo';
}

abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: isLight ? AppColors.emerald : AppColors.emeraldLight,
      onPrimary: isLight ? Colors.white : AppColors.ink,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      surface: isLight ? AppColors.cardBackground : const Color(0xFF16201B),
      onSurface: isLight ? AppColors.ink : const Color(0xFFE8E2D2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.pageBackground : const Color(0xFF101410),
      fontFamily: QuranFonts.ui,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.primaryBeige : const Color(0xFF16201B),
        foregroundColor:
            isLight ? AppColors.emeraldDark : const Color(0xFFE8E2D2),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.hairline : const Color(0xFF2A362F),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
