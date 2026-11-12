part of 'tracker_screen.dart';

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today});

  final TrackerDay today;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              loc.trackerGregorianDate(
                loc.number(today.day.day),
                loc.number(today.day.month),
                loc.number(today.day.year),
              ),
              style: AppTheme.mutedAt(Theme.of(context).colorScheme, 13),
            ),
            Text(
              loc.trackerToday,
              style: AppTheme.rowTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.today});

  final PrayerSlot slot;
  final TrackerDay today;

  String _label(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (slot) {
      PrayerSlot.fajr => loc.fajr,
      PrayerSlot.dhuhr => loc.dhuhr,
      PrayerSlot.asr => loc.asr,
      PrayerSlot.maghrib => loc.maghrib,
      PrayerSlot.isha => loc.isha,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        checked: today.forSlot(slot),
        child: ListTile(
          leading: Icon(
            today.forSlot(slot)
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: today.forSlot(slot)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          title: Text(_label(context)),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<TrackerCubit>().toggle(slot);
          },
        ),
      ),
    );
  }
}

class _Last7Row extends StatelessWidget {
  const _Last7Row({required this.last7, required this.today});

  final List<bool> last7;

  /// The newest day in [last7]; the row walks backwards from it.
  final DateTime today;

  String _dotLabel(AppLocalizations loc, int index) {
    final day = switch (index) {
      0 => loc.trackerDotToday,
      1 => loc.trackerDotYesterday,
      2 => loc.trackerDotTwoDaysAgo,
      _ => loc.trackerDotDaysAgo(loc.number(index)),
    };
    return loc.trackerDotSemantics(
      day,
      last7[index] ? loc.trackerDotMarked : loc.trackerDotUnmarked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < last7.length; i++)
          Semantics(
            container: true,
            label: _dotLabel(loc, i),
            // The weekday glyph is decoration for the eye; the label above
            // already spells the day out for screen readers.
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    last7[i] ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: last7[i] ? colors.primary : colors.outline,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Calendar arithmetic: the weekday label must not shift
                    // on a DST day the way a Duration subtraction would.
                    weekdays[DateTime(
                          today.year,
                          today.month,
                          today.day - i,
                        ).weekday %
                        7],
                    style: TextStyle(
                      fontSize: 10,
                      color: i == 0 ? colors.primary : colors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Chip(
        avatar: Icon(
          Icons.local_fire_department,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        label: Text(
          loc.streak(loc.number(streakDays)),
          style: _streakLabelStyle,
        ),
      ),
    );
  }
}
