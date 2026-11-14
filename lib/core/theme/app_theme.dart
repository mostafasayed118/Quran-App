import 'package:flutter/material.dart';

import '../domain/prayer_name.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_system_ui.dart';
import 'app_type.dart';
import 'prayer_palette.dart';

abstract final class QuranFonts {
  static const quran = 'HafsSmart';
  static const meQuran = 'me_quran';
  static const ui = 'Cairo';
}

abstract final class AppTheme {
  static const TextStyle meQuranHead =
      TextStyle(fontFamily: QuranFonts.meQuran, fontSize: AppType.titleLarge);

  /// City and degree headings rendered in the meQuran face.
  static const TextStyle meQuranTitle =
      TextStyle(fontFamily: QuranFonts.meQuran, fontSize: AppType.title);

  static const TextStyle hafsAyah = TextStyle(
      fontFamily: QuranFonts.quran,
      fontSize: AppType.quranVerse,
      height: AppType.quranHeight);

  /// The verse card's ayah number; the reader multiplies it by its own scale.
  static const TextStyle ayahNumber =
      TextStyle(fontFamily: QuranFonts.meQuran, fontSize: AppType.ayahNumber);

  /// Bold Latin-font row title used by the reciter lists.
  static const TextStyle rowTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.bodyLarge,
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
    fontSize: AppType.heroValue,
    fontWeight: FontWeight.bold,
    height: AppType.displayHeight,
  );

  static const TextStyle heroTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.headline,
    fontWeight: FontWeight.bold,
    height: AppType.heroHeight,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.bodyLarge,
    fontWeight: FontWeight.bold,
    height: AppType.cardHeight,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.body,
    fontWeight: FontWeight.bold,
    height: AppType.labelHeight,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.caption,
    height: AppType.bodyHeight,
  );

  /// The one body-paragraph style shared by the state views.
  static const TextStyle bodyText = TextStyle(
    fontFamily: QuranFonts.ui,
    fontSize: AppType.bodyLarge,
    height: AppType.relaxedHeight,
  );

  /// Shared content padding for tappable list rows.
  static const EdgeInsets tileContentPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 2);

  static Color goldText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? AppColors.goldText
          : AppColors.gold;

  static TextStyle mutedFootnote(BuildContext context) => TextStyle(
        fontSize: AppType.micro,
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

  static final Map<PrayerName, ThemeData> _lightByPeriod = {};
  static final Map<PrayerName, ThemeData> _darkByPeriod = {};

  /// The chrome for [name] at [brightness] (prayer skin on).
  ///
  /// Cached per `(PrayerName, brightness)`: the root build reads it on every
  /// rebuild, and a `ThemeData` plus a seeded `ColorScheme` is not cheap.
  static ThemeData forPrayer(PrayerName name, Brightness brightness) {
    final cache =
        brightness == Brightness.light ? _lightByPeriod : _darkByPeriod;
    return cache.putIfAbsent(
      name,
      () => _theme(brightness, PrayerPalettes.of(name, brightness)),
    );
  }

  /// Clears the per-period cache (tests; a future editable palette).
  @visibleForTesting
  static void clearPrayerCache() {
    _lightByPeriod.clear();
    _darkByPeriod.clear();
  }

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
            fontSize: AppType.stat,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: AppType.headlineLarge,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: AppType.headline,
            // AppBar titles stay regular: the app's headers are already
            // centered and heavy enough; bolding every one of them is a
            // restyle, not a consistency fix.
            fontWeight: FontWeight.w400,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: AppType.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: AppType.body,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: AppType.bodyLarge,
            fontWeight: FontWeight.w400,
            height: AppType.bodyHeight,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: AppType.body,
            fontWeight: FontWeight.w400,
            height: AppType.bodyHeight,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: AppType.caption,
            fontWeight: FontWeight.w400,
            height: AppType.labelHeight,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: AppType.body,
            fontWeight: FontWeight.w400,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: AppType.caption,
            fontWeight: FontWeight.w400,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: AppType.micro,
            fontWeight: FontWeight.w400,
            height: AppType.labelHeight,
          ),
        )
        .apply(
          fontFamily: QuranFonts.ui,
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        );
  }

  static ThemeData _theme(Brightness brightness, [PrayerPalette? palette]) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      // The seed moves with the period so every generated role (tertiary,
      // scrim tint, …) stays in the same family; the roles the app reads are
      // overridden below.
      seedColor: palette?.primary ?? AppColors.emerald,
      brightness: brightness,
      primary: palette?.primary ??
          (isLight ? AppColors.emerald : AppColors.emeraldLight),
      onPrimary: palette?.onPrimary ??
          (isLight ? AppColors.cardBackground : AppColors.ink),
      secondary:
          palette?.gold ?? (isLight ? AppColors.goldStrong : AppColors.gold),
      // Gold is a light accent: ink on it measures 3.47:1 in the light theme,
      // so white is used for text on a gold fill (5.0:1). Dark keeps the ink.
      onSecondary: palette?.onGold ??
          (isLight ? AppColors.cardBackground : AppColors.ink),
      // `fromSeed` derives `surfaceTint` from the *generated* primary, not the
      // override above; an elevated dialog would otherwise take the seeded
      // tone instead of the period's.
      surfaceTint: palette?.primary,
      surface: palette?.surface ??
          (isLight ? AppColors.cardBackground : AppColors.darkSurface),
      onSurface:
          palette?.ink ?? (isLight ? AppColors.ink : AppColors.darkOnSurface),
      // The generated container roles are cool mint; the brand highlight is a
      // warm emerald wash. Both pairings stay above 9:1.
      primaryContainer: palette?.tint ??
          (isLight ? AppColors.emeraldTintLight : AppColors.emeraldTintDark),
      onPrimaryContainer: palette?.onTint ??
          (isLight
              ? AppColors.onEmeraldTintLight
              : AppColors.onEmeraldTintDark),
      // The light container is a pale gold; on a dark surface that same pale
      // fill left the 28 dp hadith badge with `onSurface` text at 1.09:1.
      // Dark uses a dark gold wash and a gold label instead.
      secondaryContainer: palette?.secondaryContainer ??
          (isLight
              ? AppColors.goldLight
              : Color.alphaBlend(AppColors.gold.withValues(alpha: 0.18),
                  AppColors.darkSurface)),
      onSecondaryContainer: palette?.onSecondaryContainer ??
          (isLight ? AppColors.goldText : AppColors.gold),
      // Grouping surfaces (grid tiles, inset panels) read as warm paper, not
      // as the neutral grey the seed generates.
      surfaceContainerHighest:
          palette?.tile ?? (isLight ? AppColors.tileLight : AppColors.tileDark),
      // These four are generated from the seed unless overridden; with a
      // period seed the chrome would drift off-token.
      onSurfaceVariant: palette?.muted,
      outline: palette?.hairline,
      outlineVariant: palette?.hairline,
      error: palette?.error,
      onError: palette == null
          ? null
          : (isLight ? AppColors.cardBackground : AppColors.ink),
      // Derived in the palette from its own `error` (a 12% wash), so editing
      // the token moves the container and the label together.
      errorContainer: palette?.errorContainer,
      onErrorContainer: palette?.onErrorContainer,
      // The surface family Material dialogs and sheets read. Dialogs take
      // High (the tile tone, distinct from a card); sheets take Low, whose
      // fill would equal the card at `surface`, so it carries the 40% tile
      // blend instead.
      surfaceContainer: palette?.sheetSurface,
      surfaceContainerLow: palette?.sheetSurface,
      surfaceContainerHigh: palette?.tile,
      // A raw SnackBar must not fall back to a seeded inverse.
      inverseSurface: palette?.ink,
      onInverseSurface: palette?.surface,
    );
    final page = palette?.page ??
        (isLight ? AppColors.pageBackground : AppColors.darkBackground);
    final hairline = palette?.hairline ??
        (isLight ? AppColors.hairline : AppColors.darkHairline);
    final appBar = palette?.appBar ??
        (isLight ? AppColors.primaryBeige : AppColors.darkSurface);
    final appBarInk = palette?.ink ??
        (isLight ? AppColors.emeraldDark : AppColors.darkOnSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      scaffoldBackgroundColor: page,
      fontFamily: QuranFonts.ui,
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: appBarInk,
        centerTitle: true,
        systemOverlayStyle: AppSystemUi.overlayStyle(brightness),
        // A one-pixel hairline is what separates the bar from the page without
        // adding a shadow or a second surface tone. Structure, not elevation.
        shape: Border(
          bottom: BorderSide(color: hairline, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
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
          fontSize: AppType.body,
          height: AppType.relaxedHeight,
          color: colorScheme.onSurface,
        ),
        actionTextColor: palette?.goldText ??
            (isLight ? AppColors.goldText : AppColors.gold),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: hairline),
        ),
      ),
    );
  }
}
