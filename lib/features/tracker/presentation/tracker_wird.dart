part of 'tracker_screen.dart';

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
    final target = await showAppSheet<int>(
      context: context,
      isScrollControlled: true,
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
                  loc.number(p.pagesDone),
                  loc.number(KhatmaProgress.totalPages),
                ),
                style: AppTheme.mutedAt(colors, 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.wirdTodayRange(
                  loc.number(p.todayStartPage),
                  loc.number(p.todayEndPage),
                ),
                style: AppTheme.mutedAt(colors, 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.wirdRemainingDays(loc.number(p.remainingDays)),
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
      child: SingleChildScrollView(
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
                    loc.number(KhatmaProgress.dailyPagesFor(target)),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(target),
              ),
          ],
        ),
      ),
    );
  }
}
