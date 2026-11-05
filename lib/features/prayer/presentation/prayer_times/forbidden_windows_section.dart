import 'package:flutter/material.dart';

import '../../../../core/domain/prayer_name.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/forbidden_windows.dart';
import 'prayer_times_state.dart';

/// The three daily windows in which a voluntary prayer is disliked.
///
/// A card-like surface that follows the day's schedule panel; it deliberately
/// avoids the [Card] widget so the panel stays the only schedule card.
class ForbiddenWindowsSection extends StatelessWidget {
  /// Creates the section from the day's entries.
  const ForbiddenWindowsSection({super.key, required this.entries});

  /// Today's six times (sunrise included).
  final List<PrayerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final times = <PrayerName, DateTime>{
      for (final entry in entries) entry.name: entry.time,
    };
    final fajr = times[PrayerName.fajr];
    final sunrise = times[PrayerName.sunrise];
    final dhuhr = times[PrayerName.dhuhr];
    final asr = times[PrayerName.asr];
    final maghrib = times[PrayerName.maghrib];
    if (fajr == null ||
        sunrise == null ||
        dhuhr == null ||
        asr == null ||
        maghrib == null) {
      return const SizedBox.shrink();
    }
    final windows = forbiddenWindowsFor(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
    );
    if (windows.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.do_not_disturb_on_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                loc.forbiddenWindowsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.forbiddenWindowsNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          for (final window in windows) ...[
            const Divider(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  _label(loc, window.kind),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${formatHm(window.start, arabicIndic: loc.usesArabicIndicDigits)}'
                  ' – '
                  '${formatHm(window.end, arabicIndic: loc.usesArabicIndicDigits)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _label(AppLocalizations loc, ForbiddenWindowKind kind) =>
      switch (kind) {
        ForbiddenWindowKind.afterFajr => loc.forbiddenAfterFajr,
        ForbiddenWindowKind.zenith => loc.forbiddenZenith,
        ForbiddenWindowKind.afterAsr => loc.forbiddenAfterAsr,
      };
}
