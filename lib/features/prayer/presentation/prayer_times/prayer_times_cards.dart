part of 'prayer_times_screen.dart';

/// What comes after today's last prayer.
///
/// Without it the panel went silent after Isha while Home advertised
/// tomorrow's Fajr — two screens disagreeing about the same fact.
class _TomorrowNote extends StatelessWidget {
  const _TomorrowNote({
    required this.name,
    required this.time,
    required this.remaining,
    this.timezone,
  });

  final PrayerName name;
  final DateTime time;
  final Duration? remaining;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nights_stay_outlined,
                size: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.nextPrayerTomorrow(
                      name.label(loc),
                      formatHm(
                        cityWallClock(time, timezone),
                        arabicIndic: loc.usesArabicIndicDigits,
                      ),
                    ),
                    style: AppTheme.cardTitle.copyWith(fontSize: 15),
                  ),
                  if (remaining != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      loc.remaining(formatDurationHm(remaining!,
                          arabicIndic: loc.usesArabicIndicDigits)),
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => PrayerTimesScreen._openCityPicker(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cityDisplayName(city, loc.localeName),
                  style: AppTheme.meQuranTitle,
                ),
              ),
              IconButton(
                tooltip: loc.selectCity,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => PrayerTimesScreen._openCityPicker(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the prayer panel.
///
/// The next prayer is the only row with a schedule glyph and a countdown, so
/// the highlight is carried by shape and content as well as colour. Sunrise is
/// a time marker, not a prayer, and is rendered muted with a sun glyph instead
/// of the radio-button dot it used to borrow.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.entry,
    required this.remaining,
    required this.loc,
    this.timezone,
  });

  final PrayerEntry entry;
  final Duration? remaining;
  final AppLocalizations loc;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNext = entry.isNext;
    final isSunrise = entry.name == PrayerName.sunrise;
    final foreground = isNext ? colors.onPrimaryContainer : colors.onSurface;
    final muted = isNext
        ? colors.onPrimaryContainer.withValues(alpha: 0.75)
        : colors.onSurfaceVariant;

    return Container(
      decoration: isNext
          ? BoxDecoration(
              color: colors.primaryContainer,
              border: BorderDirectional(
                start: BorderSide(color: colors.primary, width: 3),
              ),
            )
          : null,
      padding: EdgeInsetsDirectional.fromSTEB(
        isNext ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (isNext)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Icon(Icons.schedule, size: 20, color: foreground),
            )
          else if (isSunrise)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Icon(Icons.wb_sunny_outlined, size: 18, color: muted),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name.label(loc),
                  style: isNext
                      ? AppTheme.cardTitle.copyWith(color: foreground)
                      : AppTheme.rowTitle.copyWith(
                          color: isSunrise ? muted : foreground,
                          fontWeight: FontWeight.w400,
                        ),
                ),
                if (isNext && remaining != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    loc.remaining(formatDurationHm(remaining!,
                        arabicIndic: loc.usesArabicIndicDigits)),
                    style: AppTheme.caption.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatHm(
              cityWallClock(entry.time, timezone),
              arabicIndic: loc.usesArabicIndicDigits,
            ),
            style: isNext
                ? AppTheme.cardTitle.copyWith(color: foreground)
                : AppTheme.rowTitle.copyWith(
                    color: isSunrise ? muted : foreground,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }
}
