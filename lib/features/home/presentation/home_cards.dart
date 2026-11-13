part of 'home_screen.dart';

/// Direction-aware disclosure chevron.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? Icons.chevron_left
          : Icons.chevron_right,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// A 44 dp tinted circle that gives an icon a place to sit.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.gold = false});

  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = gold ? colors.secondary : colors.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: AppColors.badgeTintAlpha),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.lastRead});

  final LastReadCard lastRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(quranReaderPath(
          surah: lastRead.surahId,
          ayah: lastRead.ayahNumber,
        )),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const _IconBadge(icon: Icons.menu_book_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastRead.surahName,
                      style: AppTheme.meQuranHead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.continueReadingAyah(loc.number(lastRead.ayahNumber)),
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const _Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next-prayer body: label, name, wall-clock time, city and countdown.
///
/// Extracted from the old card so [_TodayPanel] can place it inside one
/// surface with the continue-reading row.
class _PrayerBody extends StatelessWidget {
  const _PrayerBody({
    required this.prayer,
    this.timezone,
    this.cityNameEn,
  });

  final NextPrayerCard prayer;
  final String? timezone;
  final String? cityNameEn;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _IconBadge(icon: Icons.schedule, gold: true),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                loc.nextPrayer,
                style: AppTheme.caption.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const _Chevron(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.name.label(loc),
                    style: AppTheme.heroTitle
                        .copyWith(color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Time and city travel together so the block reads
                  // "name, at this time, in this place" at a glance.
                  Wrap(
                    spacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatHm(
                          cityWallClock(prayer.time, timezone),
                          arabicIndic: loc.usesArabicIndicDigits,
                        ),
                        style: AppTheme.caption.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                      Text(
                        loc.localeName == 'ar'
                            ? prayer.cityName
                            : (cityNameEn ?? prayer.cityName),
                        style: AppTheme.caption.copyWith(
                          color:
                              colors.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // The countdown is the one number that moves; it gets the
            // opposite side of the card so the eye can find it without
            // scanning. It only scales down when a 2.0 text scale would
            // otherwise break the row.
            Flexible(
              flex: 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: _LiveCountdown(target: prayer.time),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Counts down to [target] once a second, and only while the app is resumed.
///
/// Kept as its own widget so the tick rebuilds one text line instead of the
/// whole dashboard. The timer lives behind `LifecycleTicker`, so a dashboard
/// left open behind another app stops waking the CPU every second; the parent
/// cubit reloads the card when the prayer actually passes.
class _LiveCountdown extends StatelessWidget {
  const _LiveCountdown({required this.target});

  final DateTime target;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return LifecycleTicker(
      builder: (context, _) => Text(
        formatDurationHms(
          target.difference(DateTime.now()),
          arabicIndic: loc.usesArabicIndicDigits,
        ),
        style: AppTheme.heroValue.copyWith(color: colors.onPrimaryContainer),
        maxLines: 2,
      ),
    );
  }
}

class _NoCityCard extends StatelessWidget {
  const _NoCityCard();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => HomeScreen._openCityPicker(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const _IconBadge(icon: Icons.location_on_outlined, gold: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.selectCity, style: AppTheme.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      loc.noCity,
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const _Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The home's focal panel: what you were reading and the prayer that is
/// coming, on one surface with a hairline between them.
///
/// Two equal cards made the first screen read as a list of unrelated blocks.
/// One panel with an internal division gives the page a single anchor without
/// demoting either action — the editorial move the section headers already use.
class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.lastRead,
    required this.prayer,
    this.timezone,
    this.cityNameEn,
  });

  final LastReadCard? lastRead;
  final NextPrayerCard prayer;
  final String? timezone;
  final String? cityNameEn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastRead = this.lastRead;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lastRead != null) ...[
            InkWell(
              onTap: () => context.push(quranReaderPath(
                surah: lastRead.surahId,
                ayah: lastRead.ayahNumber,
              )),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _ContinueRow(lastRead: lastRead),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: colors.onPrimaryContainer.withValues(alpha: 0.12),
            ),
          ],
          InkWell(
            onTap: () => context.push(AppRoutes.prayerTimes),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _PrayerBody(
                prayer: prayer,
                timezone: timezone,
                cityNameEn: cityNameEn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The continue-reading line inside [_TodayPanel].
class _ContinueRow extends StatelessWidget {
  const _ContinueRow({required this.lastRead});

  final LastReadCard lastRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
    return Row(
      children: [
        const _IconBadge(icon: Icons.menu_book_rounded),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastRead.surahName,
                style: AppTheme.meQuranHead.copyWith(
                  color: colors.onPrimaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                loc.continueReadingAyah(loc.number(lastRead.ayahNumber)),
                style: AppTheme.caption.copyWith(
                  color: colors.onPrimaryContainer.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          chevron,
          color: colors.onPrimaryContainer.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
