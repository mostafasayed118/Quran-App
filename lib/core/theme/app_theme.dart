import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_system_ui.dart';

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

  /// Named type steps for the dashboard-style surfaces.
  ///
  /// They live here — not inline in the widgets — so the ramp of a screen can
  /// be read in one place. Cairo ships 400/700 only (see `pubspec.yaml`), so
  /// every "medium" weight below would silently render at 400; the ramp uses
  /// size and colour for hierarchy instead of a weight the font cannot draw.
  static const TextStyle heroValue = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 30,
    fontWeight: FontWeight.bold,
    height: 1.15,
  );

  static const TextStyle heroTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 21,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.35,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 13,
    height: 1.5,
  );

  /// The one body-paragraph style shared by the state views.
  static const TextStyle bodyText = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: 15,
    height: 1.6,
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

  // `_theme` builds a full ColorScheme.fromSeed palette plus ThemeData, and the
  // root build in lib/app/app.dart reads both getters on every rebuild, so the
  // built objects are cached. Static finals are lazily initialized: nothing is
  // computed until the first read.
  static final ThemeData _light = _theme(Brightness.light);
  static final ThemeData _dark = _theme(Brightness.dark);

  static ThemeData get light => _light;
  static ThemeData get dark => _dark;

  /// The app's type ramp, in the slots Material components already read.
  ///
  /// Two constraints shape it:
  ///  * Cairo ships **400 and 700 only** (see `pubspec.yaml`), so every weight
  ///    here is one of those two. The previous M3 defaults asked for 500, which
  ///    silently rendered as 400 — a hierarchy that existed only in source.
  ///  * The metrics (size/height) match Material 3 on purpose, so adopting the
  ///    theme does not reflow a single existing screen.
  ///
  /// Screen-level semantic steps stay in [AppTheme] (`heroValue`, `cardTitle`,
  /// `caption`, …) because they are not Material roles; this ramp is what
  /// dialogs, list tiles, buttons, tabs, fields and snackbars inherit.
  static TextTheme _textTheme(ColorScheme colors) {
    final base = Typography.material2021().black;
    return base
        .copyWith(
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 22,
            // AppBar titles stay regular: the app's headers are already
            // centered and heavy enough; bolding every one of them is a
            // restyle, not a consistency fix.
            fontWeight: FontWeight.w400,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        )
        .apply(
          fontFamily: QuranFonts.ui,
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        );
  }

  static ThemeData _theme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: isLight ? AppColors.emerald : AppColors.emeraldLight,
      onPrimary: isLight ? AppColors.cardBackground : AppColors.ink,
      secondary: AppColors.gold,
      // Gold is a light accent: white on it is ~2.2:1. Ink keeps the token
      // usable if a component ever puts text on `secondary`.
      onSecondary: AppColors.ink,
      surface: isLight ? AppColors.cardBackground : AppColors.darkSurface,
      onSurface: isLight ? AppColors.ink : AppColors.darkOnSurface,
      // The generated container roles are cool mint; the brand highlight is a
      // warm emerald wash. Both pairings stay above 9:1.
      primaryContainer:
          isLight ? AppColors.emeraldTintLight : AppColors.emeraldTintDark,
      onPrimaryContainer:
          isLight ? AppColors.onEmeraldTintLight : AppColors.onEmeraldTintDark,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.goldText,
      // Grouping surfaces (grid tiles, inset panels) read as warm paper, not
      // as the neutral grey the seed generates.
      surfaceContainerHighest:
          isLight ? AppColors.tileLight : AppColors.tileDark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      scaffoldBackgroundColor:
          isLight ? AppColors.pageBackground : AppColors.darkBackground,
      fontFamily: QuranFonts.ui,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.primaryBeige : AppColors.darkSurface,
        foregroundColor:
            isLight ? AppColors.emeraldDark : AppColors.darkOnSurface,
        centerTitle: true,
        systemOverlayStyle: AppSystemUi.overlayStyle(brightness),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: isLight ? AppColors.hairline : AppColors.darkHairline,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.hairline : AppColors.darkHairline,
        thickness: 1,
        // `space` is left at the Material default: untouched screens
        // (settings, licenses) use a bare `Divider()` for section spacing.
      ),
      // The safety net behind `AppToast`: a raw SnackBar (or one a future
      // screen writes without the helper) still reads as this app — paper
      // surface, hairline, soft elevation — instead of Material's dark
      // inverse bar.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(
          fontFamily: QuranFonts.ui,
          fontSize: 14,
          height: 1.6,
          color: colorScheme.onSurface,
        ),
        actionTextColor: isLight ? AppColors.goldText : AppColors.gold,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: isLight ? AppColors.hairline : AppColors.darkHairline,
          ),
        ),
      ),
    );
  }
}
