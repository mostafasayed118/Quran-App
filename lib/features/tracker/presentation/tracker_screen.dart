import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/prayer_log_repository.dart';
import 'tracker_cubit.dart';
import 'tracker_state.dart';

const TextStyle _todayTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
);

const TextStyle _streakLabelStyle = TextStyle(fontSize: 12);

TextStyle _mutedAt(ColorScheme colors, double fontSize) =>
    TextStyle(fontSize: fontSize, color: colors.onSurfaceVariant);

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.worshipTracker)),
      body: BlocBuilder<TrackerCubit, TrackerState>(
        builder: (context, state) => switch (state) {
          TrackerLoading() => const LoadingView(),
          TrackerFailed() => errorPane(loc),
          TrackerReady(:final today, :final streakDays, :final last7) =>
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _TodayCard(today: today),
                const SizedBox(height: 8),
                for (final slot in PrayerSlot.values)
                  _SlotTile(slot: slot, today: today),
                const SizedBox(height: 12),
                Text(
                  loc.last7Days,
                  style: _mutedAt(Theme.of(context).colorScheme, 12),
                ),
                const SizedBox(height: 6),
                _Last7Row(last7: last7),
                if (streakDays > 0) _StreakChip(streakDays: streakDays),
              ],
            ),
        },
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today});

  final TrackerDay today;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '${today.day.year}/${today.day.month}/${today.day.day}'
                  .toArabicIndicDigits,
              style: _mutedAt(Theme.of(context).colorScheme, 13),
            ),
            Text(
              loc.trackerToday,
              style: _todayTitleStyle,
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
  const _Last7Row({required this.last7});

  final List<bool> last7;

  String _dotLabel(AppLocalizations loc, int index) {
    final day = switch (index) {
      0 => loc.trackerDotToday,
      1 => loc.trackerDotYesterday,
      2 => loc.trackerDotTwoDaysAgo,
      _ => loc.trackerDotDaysAgo(index.toArabicIndic),
    };
    return '$day: ${last7[index] ? loc.trackerDotMarked : loc.trackerDotUnmarked}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < last7.length; i++)
          Semantics(
            container: true,
            label: _dotLabel(loc, i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                last7[i] ? Icons.circle : Icons.circle_outlined,
                size: 14,
                color: last7[i]
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
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
          loc.streak(streakDays.toArabicIndic),
          style: _streakLabelStyle,
        ),
      ),
    );
  }
}
