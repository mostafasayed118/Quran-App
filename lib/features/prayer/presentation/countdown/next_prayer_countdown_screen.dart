import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/next_prayer_focus.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/city_clock.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/lifecycle_ticker.dart';
import '../../../../l10n/app_localizations.dart';

/// The next prayer, full screen.
///
/// The home card shows the countdown at the size a card allows, where Cairo's
/// Arabic-Indic pairs sit almost on top of each other (2026-11-13 UI audit,
/// finding U-4: tracking is inert inside an Arabic script run and the only
/// other bundled family draws the digits as boxes). Here the clock is
/// **composed from one box per digit**, so the spacing is explicit and the
/// digits cannot collide at any text scale.
class NextPrayerCountdownScreen extends StatelessWidget {
  /// Creates the screen.
  const NextPrayerCountdownScreen({super.key, this.focus});

  /// The prayer the home handed over, or null when the route was opened
  /// without it (a deep link, a restored route).
  final NextPrayerFocus? focus;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final focus = this.focus;
    return Scaffold(
      appBar: AppBar(title: Text(loc.nextPrayer)),
      body: AppContentFrame(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              if (focus == null)
                _MissingFocus(message: loc.noCity)
              else ...[
                _FocusHeader(focus: focus),
                const SizedBox(height: AppSpacing.xl),
                _DigitClock(
                  target: focus.time,
                  arabicIndic: loc.usesArabicIndicDigits,
                  overLabel: loc.reminderNextPrayer(focus.prayer.label(loc)),
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.prayerTimes),
                icon: const Icon(Icons.schedule),
                label: Text(loc.prayerTimes),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusHeader extends StatelessWidget {
  const _FocusHeader({required this.focus});

  final NextPrayerFocus focus;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          focus.prayer.label(loc),
          textAlign: TextAlign.center,
          style: AppTheme.heroTitle.copyWith(
            color: colors.onSurface,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatHm(
                cityWallClock(focus.time, focus.timezone),
                arabicIndic: loc.usesArabicIndicDigits,
              ),
              style: AppTheme.rowTitle.copyWith(color: colors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              focus.cityName,
              style: AppTheme.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

/// The countdown, one box per digit.
///
/// [formatDurationHms] still produces the string (and stays the single source
/// of the format); this widget only decides how it is laid out.
class _DigitClock extends StatelessWidget {
  const _DigitClock({
    required this.target,
    required this.arabicIndic,
    required this.overLabel,
  });

  final DateTime target;
  final bool arabicIndic;

  /// Shown once the target has passed; the clock stops at zero.
  final String overLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LifecycleTicker(
      builder: (context, _) {
        final remaining = target.difference(DateTime.now());
        final digits = formatDurationHms(remaining, arabicIndic: arabicIndic);
        return Column(
          children: [
            Semantics(
              // One announcement for the whole clock: a screen reader should
              // read "٠١:٠٢:٠٣", not eight separate glyphs.
              label: digits,
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // The clock reads left-to-right in both locales: digits are
                // numerals, not script.
                textDirection: TextDirection.ltr,
                children: [
                  for (final rune in digits.split(''))
                    rune == ':'
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: Text(
                              ':',
                              style: AppTheme.heroTitle.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 34,
                              ),
                            ),
                          )
                        : Container(
                            width: 34,
                            alignment: Alignment.center,
                            child: Text(
                              rune,
                              style: AppTheme.heroTitle.copyWith(
                                color: colors.onSurface,
                                fontSize: 44,
                                height: 1.1,
                              ),
                            ),
                          ),
                ],
              ),
            ),
            if (remaining.isNegative || remaining == Duration.zero) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                overLabel,
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(color: colors.primary),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MissingFocus extends StatelessWidget {
  const _MissingFocus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.schedule, size: 48, color: colors.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
