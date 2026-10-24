import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/khatma_progress.dart';
import '../data/prayer_log_repository.dart';
import 'tracker_cubit.dart';
import 'tracker_state.dart';

const TextStyle _streakLabelStyle = TextStyle(fontSize: 12);

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.worshipTracker)),
      body: BlocListener<TrackerCubit, TrackerState>(
        listenWhen: (previous, current) =>
            previous is TrackerReady &&
            !previous.actionFailed &&
            current is TrackerReady &&
            current.actionFailed,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.genericError)),
          );
          context.read<TrackerCubit>().acknowledgeActionFailure();
        },
        child: BlocBuilder<TrackerCubit, TrackerState>(
          builder: (context, state) => switch (state) {
            TrackerLoading() => const LoadingView(),
            TrackerFailed() => errorPane(loc),
            TrackerReady(
              :final today,
              :final streakDays,
              :final last7,
              :final khatmaAvailable,
              :final khatma,
            ) =>
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _TodayCard(today: today),
                  const SizedBox(height: AppSpacing.sm),
                  for (final slot in PrayerSlot.values)
                    _SlotTile(slot: slot, today: today),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    loc.last7Days,
                    style: AppTheme.mutedAt(Theme.of(context).colorScheme, 12),
                  ),
                  const SizedBox(height: 6),
                  _Last7Row(last7: last7),
                  if (streakDays > 0) _StreakChip(streakDays: streakDays),
                  if (khatmaAvailable) ...[
                    const SizedBox(height: AppSpacing.md),
                    _WirdCard(progress: khatma),
                  ],
                ],
              ),
          },
        ),
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              loc.trackerGregorianDate(
                today.day.day.toArabicIndic,
                today.day.month.toArabicIndic,
                today.day.year.toArabicIndic,
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
  const _Last7Row({required this.last7});

  final List<bool> last7;

  String _dotLabel(AppLocalizations loc, int index) {
    final day = switch (index) {
      0 => loc.trackerDotToday,
      1 => loc.trackerDotYesterday,
      2 => loc.trackerDotTwoDaysAgo,
      _ => loc.trackerDotDaysAgo(index.toArabicIndic),
    };
    return loc.trackerDotSemantics(
      day,
      last7[index] ? loc.trackerDotMarked : loc.trackerDotUnmarked,
    );
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

/// Reader route opening the wird at the plan's read-up-to pointer.
String wirdReaderRoute(KhatmaProgress progress) => quranReaderPath(
      surah: progress.readerSurahId,
      ayah: progress.readerAyahNumber,
    );

class _WirdCard extends StatelessWidget {
  const _WirdCard({required this.progress});

  /// Active plan view; null while the card is in its setup state.
  final KhatmaProgress? progress;

  Future<void> _openSetupSheet(BuildContext context) async {
    final cubit = context.read<TrackerCubit>();
    final target = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => const _WirdSetupSheet(),
    );
    if (target != null) await cubit.startKhatma(target);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final p = progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(loc.wirdTitle, style: AppTheme.rowTitle),
              ],
            ),
            if (p == null) ...[
              const SizedBox(height: 6),
              Text(loc.wirdSetupHint, style: AppTheme.mutedAt(colors, 13)),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => _openSetupSheet(context),
                child: Text(loc.wirdStart),
              ),
            ] else if (p.completed) ...[
              const SizedBox(height: 6),
              Text(loc.wirdCompleted, style: AppTheme.mutedAt(colors, 13)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.read<TrackerCubit>().resetKhatma(),
                child: Text(loc.wirdNewPlan),
              ),
            ] else ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: p.fraction),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.wirdProgress(
                  p.pagesDone.toArabicIndic,
                  KhatmaProgress.totalPages.toArabicIndic,
                ),
                style: AppTheme.mutedAt(colors, 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.wirdTodayRange(
                  p.todayStartPage.toArabicIndic,
                  p.todayEndPage.toArabicIndic,
                ),
                style: AppTheme.mutedAt(colors, 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.wirdRemainingDays(p.remainingDays.toArabicIndic),
                style: AppTheme.mutedAt(colors, 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          context.read<TrackerCubit>().finishWirdToday(),
                      child: Text(loc.wirdFinishToday),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push(wirdReaderRoute(p)),
                      child: Text(loc.wirdOpenToday),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WirdSetupSheet extends StatelessWidget {
  const _WirdSetupSheet();

  String _paceLabel(AppLocalizations loc, int targetPages) =>
      switch (targetPages) {
        KhatmaProgress.pagesPerMonth => loc.wirdPaceMonthly,
        KhatmaProgress.pagesPerTwoMonths => loc.wirdPaceTwoMonths,
        KhatmaProgress.pagesPerThreeMonths => loc.wirdPaceThreeMonths,
        _ => loc.wirdPaceFourMonths,
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, 6),
            child: Text(loc.wirdPaceSheetTitle, style: AppTheme.rowTitle),
          ),
          for (final target in KhatmaProgress.targetChoices)
            ListTile(
              title: Text(_paceLabel(loc, target)),
              subtitle: Text(
                loc.wirdDailyPages(
                  KhatmaProgress.dailyPagesFor(target).toArabicIndic,
                ),
              ),
              onTap: () => Navigator.of(context).pop(target),
            ),
        ],
      ),
    );
  }
}
