import 'package:flutter/material.dart';

import '../domain/prayer_name.dart';

/// One prayer period's palette for one brightness.
///
/// The reader, the mushaf page, the share card and the splash never read this;
/// only the chrome does. [gold] is the constant signature and is graphics-only;
/// [goldText] is the text weight of the same gold.
///
/// The containers are **derived** from the tokens (never copied hexes), so
/// editing [error] moves the container and its label together.
@immutable
class PrayerPalette {
  const PrayerPalette({
    required this.brightness,
    required this.page,
    required this.surface,
    required this.tile,
    required this.hairline,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.tint,
    required this.onTint,
    required this.gold,
    required this.goldText,
    required this.onGold,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Brightness brightness;
  final Color page;
  final Color surface;
  final Color tile;
  final Color hairline;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color tint;
  final Color onTint;
  final Color gold;
  final Color goldText;
  final Color onGold;

  /// Always paired with an icon and a label: colour alone is not a signal
  /// (deuteranopia collapses several of these pairs).
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// A pale gold wash behind a chip or badge.
  Color get secondaryContainer =>
      Color.alphaBlend(gold.withValues(alpha: 0.14), surface);

  Color get onSecondaryContainer => goldText;

  /// A warm error wash; the label darkens in light so it does not sit at the
  /// 5.1 AA edge.
  Color get errorContainer =>
      Color.alphaBlend(error.withValues(alpha: 0.12), surface);

  Color get onErrorContainer => brightness == Brightness.light
      ? Color.alphaBlend(Colors.black.withValues(alpha: 0.22), error)
      : error;

  /// The chrome bar: the page tinted 6% toward the period primary.
  Color get appBar => Color.alphaBlend(primary.withValues(alpha: 0.06), page);

  /// The raised panels a sheet or a navigation bar paints.
  ///
  /// A modal sheet defaults to `surfaceContainerLow`; at [surface] it would be
  /// the exact fill of a card beneath it, with nothing but the scrim between
  /// them. The tile tone at 40% keeps the sheet in the period family while
  /// separating it from the card it covers.
  Color get sheetSurface =>
      Color.alphaBlend(tile.withValues(alpha: 0.40), surface);
}

/// The twelve palettes, one per prayer and brightness.
abstract final class PrayerPalettes {
  static PrayerPalette of(PrayerName name, Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (name) {
      PrayerName.fajr => light ? _fajrLight : _fajrDark,
      PrayerName.sunrise => light ? _sunriseLight : _sunriseDark,
      PrayerName.dhuhr => light ? _dhuhrLight : _dhuhrDark,
      PrayerName.asr => light ? _asrLight : _asrDark,
      PrayerName.maghrib => light ? _maghribLight : _maghribDark,
      PrayerName.isha => light ? _ishaLight : _ishaDark,
    };
  }

  static const PrayerPalette _fajrLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFF3EFF5),
    surface: Color(0xFFFCF9FF),
    tile: Color(0xFFE9DFF0),
    hairline: Color(0xFFDAD7DD),
    ink: Color(0xFF26232F),
    muted: Color(0xFF64606A),
    primary: Color(0xFF6D4C7D),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFE9DFF0),
    onTint: Color(0xFF26232F),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _sunriseLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFFBF0EA),
    surface: Color(0xFFFFF9F5),
    tile: Color(0xFFF6E0DA),
    hairline: Color(0xFFE2D7D2),
    ink: Color(0xFF2C2320),
    muted: Color(0xFF6A615D),
    primary: Color(0xFF9E4A58),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFF6E0DA),
    onTint: Color(0xFF2C2320),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _dhuhrLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFEFE9DA),
    surface: Color(0xFFFFFDF7),
    tile: Color(0xFFDCE8E1),
    hairline: Color(0xFFD7D2C5),
    ink: Color(0xFF232D28),
    muted: Color(0xFF60655D),
    primary: Color(0xFF3E6B58),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFDCE8E1),
    onTint: Color(0xFF232D28),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _asrLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFEDF1E7),
    surface: Color(0xFFF9FCF4),
    tile: Color(0xFFDEE8D8),
    hairline: Color(0xFFD5D9D0),
    ink: Color(0xFF232D28),
    muted: Color(0xFF606861),
    primary: Color(0xFF566F45),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFDEE8D8),
    onTint: Color(0xFF232D28),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _maghribLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFF8ECE4),
    surface: Color(0xFFFFF8F2),
    tile: Color(0xFFF3DDD0),
    hairline: Color(0xFFE0D4CC),
    ink: Color(0xFF2E2320),
    muted: Color(0xFF6B5F5B),
    primary: Color(0xFF9E4B29),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFF3DDD0),
    onTint: Color(0xFF2E2320),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _ishaLight = PrayerPalette(
    brightness: Brightness.light,
    page: Color(0xFFEDEEF5),
    surface: Color(0xFFF9FAFF),
    tile: Color(0xFFDFE2F0),
    hairline: Color(0xFFD5D6DD),
    ink: Color(0xFF22252E),
    muted: Color(0xFF5F616A),
    primary: Color(0xFF3F4E8C),
    onPrimary: Color(0xFFFFFDF7),
    tint: Color(0xFFDFE2F0),
    onTint: Color(0xFF22252E),
    gold: Color(0xFFB06F18),
    goldText: Color(0xFF8A5A14),
    onGold: Color(0xFFFFFDF7),
    success: Color(0xFF14603C),
    warning: Color(0xFF7A4E00),
    error: Color(0xFFB3261E),
    info: Color(0xFF0E7490),
  );
  static const PrayerPalette _fajrDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF151021),
    surface: Color(0xFF1D1730),
    tile: Color(0xFF2A1F40),
    hairline: Color(0xFF3A344B),
    ink: Color(0xFFECE6F4),
    muted: Color(0xFFA6A0B1),
    primary: Color(0xFFC9A7E0),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF2A1F40),
    onTint: Color(0xFFECE6F4),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
  static const PrayerPalette _sunriseDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF1E1513),
    surface: Color(0xFF281D1A),
    tile: Color(0xFF3A2522),
    hairline: Color(0xFF453A36),
    ink: Color(0xFFF4E9E3),
    muted: Color(0xFFAFA49F),
    primary: Color(0xFFD96A7E),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF3A2522),
    onTint: Color(0xFFF4E9E3),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
  static const PrayerPalette _dhuhrDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF101410),
    surface: Color(0xFF16201B),
    tile: Color(0xFF1E2F27),
    hairline: Color(0xFF333B35),
    ink: Color(0xFFE8E2D2),
    muted: Color(0xFFA1A094),
    primary: Color(0xFF8CC7A8),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF1E2F27),
    onTint: Color(0xFFE8E2D2),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
  static const PrayerPalette _asrDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF131A13),
    surface: Color(0xFF1A231B),
    tile: Color(0xFF243026),
    hairline: Color(0xFF373F36),
    ink: Color(0xFFE6E8DA),
    muted: Color(0xFFA1A599),
    primary: Color(0xFFA8C08A),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF243026),
    onTint: Color(0xFFE6E8DA),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
  static const PrayerPalette _maghribDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF1F1410),
    surface: Color(0xFF291A14),
    tile: Color(0xFF3A241B),
    hairline: Color(0xFF45362F),
    ink: Color(0xFFF2E4D8),
    muted: Color(0xFFAE9F95),
    primary: Color(0xFFE58A5E),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF3A241B),
    onTint: Color(0xFFF2E4D8),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
  static const PrayerPalette _ishaDark = PrayerPalette(
    brightness: Brightness.dark,
    page: Color(0xFF0E1222),
    surface: Color(0xFF151A2E),
    tile: Color(0xFF1D2440),
    hairline: Color(0xFF323749),
    ink: Color(0xFFE7E8F2),
    muted: Color(0xFFA0A2AF),
    primary: Color(0xFF8FA0D8),
    onPrimary: Color(0xFF101410),
    tint: Color(0xFF1D2440),
    onTint: Color(0xFFE7E8F2),
    gold: Color(0xFFE3A53E),
    goldText: Color(0xFFE3A53E),
    onGold: Color(0xFF101410),
    success: Color(0xFF6FD3A0),
    warning: Color(0xFFF0B45A),
    error: Color(0xFFFF8A80),
    info: Color(0xFF67E8F9),
  );
}
