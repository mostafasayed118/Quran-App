import 'package:flutter/material.dart';

/// The type scale.
///
/// Two tiers:
///
/// * [ladder] — the twelve sizes every surface may choose from.
/// * the component tokens below — four values a single surface owns. The share
///   card is a fixed 360 dp export, the splash wordmark is brand, and the two
///   counters are designed one-offs; forcing them onto a rung would have been
///   a silent 2 px redesign.
///
/// Widgets read these through [AppTheme] or `Theme.of(context).textTheme`;
/// `test/typography_guard_test.dart` fails any numeric `fontSize:` outside
/// `lib/core/theme/`.
abstract final class AppType {
  // --- the ladder ---------------------------------------------------------

  /// Footnotes and dense labels (Material 3 `labelSmall`). The smallest rung.
  static const double micro = 11;

  /// Captions and secondary labels.
  static const double caption = 12;

  /// List subtitles and dense UI body.
  static const double body = 14;

  /// Paragraphs, card titles and row titles.
  static const double bodyLarge = 16;

  /// Quran and UI titles, reading body.
  static const double title = 18;

  /// Page titles and `meQuranHead`.
  static const double titleLarge = 20;

  /// `heroTitle` and app-bar titles.
  static const double headline = 22;

  /// `hafsAyah` and screen heroes.
  static const double headlineLarge = 24;

  /// The ayah number and `headlineMedium`.
  static const double stat = 28;

  /// The countdown's main line.
  static const double timerLarge = 40;

  /// The countdown's focus line.
  static const double timerHuge = 44;

  /// The tasbih counter.
  static const double counter = 56;

  /// Every rung, ascending. The guard and the tests read this.
  static final Set<double> ladder = <double>{
    micro,
    caption,
    body,
    bodyLarge,
    title,
    titleLarge,
    headline,
    headlineLarge,
    stat,
    timerLarge,
    timerHuge,
    counter,
  };

  // --- component tokens ---------------------------------------------------

  /// The share card's footer; the card is a fixed 360 dp export.
  static const double shareFooter = 10;

  /// The boot wordmark.
  static const double splashWordmark = 26;

  /// The home hero number.
  static const double heroValue = 30;

  /// The next-prayer countdown digit.
  static const double countdownDigit = 34;

  /// The four values a component owns instead of a rung.
  static final Set<double> componentSizes = <double>{
    shareFooter,
    splashWordmark,
    heroValue,
    countdownDigit,
  };

  // --- Quran aliases ------------------------------------------------------

  /// The continuous mushaf text.
  static const double quranMushaf = headline;

  /// The verse card's ayah text.
  static const double quranVerse = headlineLarge;

  /// The verse card's ayah number (multiplied by the reader's font scale).
  static const double ayahNumber = stat;

  // --- line heights -------------------------------------------------------

  /// A display number's line box.
  static const double displayHeight = 1.15;

  /// A hero title's line box.
  static const double heroHeight = 1.25;

  /// A card title's line box.
  static const double cardHeight = 1.35;

  /// A label's line box.
  static const double labelHeight = 1.4;

  /// A body's line box.
  static const double bodyHeight = 1.5;

  /// A paragraph's line box.
  static const double relaxedHeight = 1.6;

  /// The Quran's line box.
  static const double quranHeight = 2.0;

  // --- weights ------------------------------------------------------------

  /// The only weights Cairo ships. Anything else renders as 400.
  static final Set<FontWeight> weights = <FontWeight>{
    FontWeight.w400,
    FontWeight.w700,
  };
}
