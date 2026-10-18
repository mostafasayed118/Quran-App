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
          TrackerFailed() => errorPane(loc, 'tracker load failed', 'tracker'),
          TrackerReady(:final today, :final streakDays, :final last7) =>
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '${today.day.year}/${today.day.month}/${today.day.day}'
                              .toArabicIndicDigits,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          loc.trackerToday,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final slot in PrayerSlot.values)
                  Card(
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
                        title: Text(_label(context, slot)),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<TrackerCubit>().toggle(slot);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  loc.last7Days,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < last7.length; i++)
                      Semantics(
                        container: true,
                        label: _dotLabel(loc, i, last7[i]),
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
                ),
                if (streakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Chip(
                      avatar: Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      label: Text(
                        loc.streak(streakDays.toArabicIndic),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
        },
      ),
    );
  }

  String _dotLabel(AppLocalizations loc, int index, bool marked) {
    final day = switch (index) {
      0 => loc.trackerDotToday,
      1 => loc.trackerDotYesterday,
      2 => loc.trackerDotTwoDaysAgo,
      _ => loc.trackerDotDaysAgo(index.toArabicIndic),
    };
    return '$day: ${marked ? loc.trackerDotMarked : loc.trackerDotUnmarked}';
  }

  String _label(BuildContext context, PrayerSlot slot) {
    final loc = AppLocalizations.of(context);
    return switch (slot) {
      PrayerSlot.fajr => loc.fajr,
      PrayerSlot.dhuhr => loc.dhuhr,
      PrayerSlot.asr => loc.asr,
      PrayerSlot.maghrib => loc.maghrib,
      PrayerSlot.isha => loc.isha,
    };
  }
}
