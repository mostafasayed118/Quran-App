import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class QuranFonts {
  static const quran = 'HafsSmart';
  static const meQuran = 'me_quran';
  static const ui = 'Cairo';
}

abstract final class AppTheme {
  static const TextStyle meQuranHead =
      TextStyle(fontFamily: QuranFonts.meQuran, fontSize: 20);

  /// City and degree headings rendered in the meQuran face.
  static const TextStyle meQuranTitle =
      TextStyle(fontFamily: QuranFonts.meQuran, fontSize: 18);

  static const TextStyle hafsAyah =
      TextStyle(fontFamily: QuranFonts.quran, fontSize: 24, height: 2);

  /// Bold Latin-font row title used by the reciter lists.
  static const TextStyle rowTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  /// Shared content padding for tappable list rows.
  static const EdgeInsets tileContentPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 2);

  static Color goldText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? AppColors.goldText
          : AppColors.gold;

  static TextStyle mutedFootnote(BuildContext context) => TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// Muted secondary text at [fontSize]
  /// ([mutedFootnote]'s treatment with a call-site size).
  static TextStyle mutedAt(ColorScheme colors, double fontSize) =>
      TextStyle(fontSize: fontSize, color: colors.onSurfaceVariant);

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
      surface: isLight ? AppColors.cardBackground : AppColors.darkSurface,
      onSurface: isLight ? AppColors.ink : AppColors.darkOnSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.pageBackground : AppColors.darkBackground,
      fontFamily: QuranFonts.ui,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.primaryBeige : AppColors.darkSurface,
        foregroundColor:
            isLight ? AppColors.emeraldDark : AppColors.darkOnSurface,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.hairline : AppColors.darkHairline,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
