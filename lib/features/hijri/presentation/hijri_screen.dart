import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/utils/pager_icons.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/hijri_service.dart';
import 'hijri_cubit.dart';
import 'hijri_state.dart';

class HijriScreen extends StatelessWidget {
  const HijriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.hijriCalendar)),
      body: AppContentFrame(
        child: BlocBuilder<HijriCubit, HijriState>(
          builder: (context, state) => switch (state) {
            HijriLoading() => const LoadingView(),
            HijriFailed() =>
              errorPane(loc, onRetry: context.read<HijriCubit>().start),
            HijriReady(
              :final monthName,
              :final year,
              :final offset,
              :final cells,
              :final todayHeader,
              :final dayOffset,
            ) =>
              ListView(
                padding: appScrollPadding(
                  context,
                  const EdgeInsets.all(AppSpacing.md),
                ),
                children: [
                  _TodayCard(todayHeader: loc.digits(todayHeader)),
                  _OffsetCard(dayOffset: dayOffset),
                  _MonthNavBar(monthName: monthName, year: year),
                  _MonthGrid(offset: offset, cells: cells),
                ],
              ),
          },
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todayHeader});

  final String todayHeader;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              todayHeader,
              style: AppTheme.rowTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _OffsetCard extends StatelessWidget {
  const _OffsetCard({required this.dayOffset});

  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<HijriCubit>();
    final value = dayOffset > 0
        ? '+${loc.digits('$dayOffset')}'
        : loc.digits('$dayOffset');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            IconButton(
              tooltip: loc.hijriOffsetMinus,
              onPressed: dayOffset <= HijriService.minOffsetDays
                  ? null
                  : () => cubit.setOffset(dayOffset - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.hijriOffsetTitle,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    loc.hijriOffsetValue(value),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: loc.hijriOffsetPlus,
              onPressed: dayOffset >= HijriService.maxOffsetDays
                  ? null
                  : () => cubit.setOffset(dayOffset + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthNavBar extends StatelessWidget {
  const _MonthNavBar({required this.monthName, required this.year});

  final String monthName;
  final int year;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final direction = Directionality.of(context);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        IconButton(
          tooltip: loc.nextMonth,
          icon: Icon(pagerChevronFor(direction, next: true)),
          onPressed: () => context.read<HijriCubit>().next(),
        ),
        Expanded(
          child: Text(
            loc.hijriDate(monthName, loc.number(year)),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        IconButton(
          tooltip: loc.jumpToToday,
          icon: const Icon(Icons.today),
          onPressed: () => context.read<HijriCubit>().jumpToToday(),
        ),
        IconButton(
          tooltip: loc.previousMonth,
          icon: Icon(pagerChevronFor(direction, next: false)),
          onPressed: () => context.read<HijriCubit>().prev(),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.offset, required this.cells});

  final int offset;
  final List<HijriCell> cells;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.82,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      children: [
        for (var i = 0; i < offset; i++) const SizedBox.shrink(),
        for (final cell in cells) _DayCell(cell: cell),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.cell});

  final HijriCell cell;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final label = loc.hijriCellSemantics(
      loc.number(cell.hDay),
      loc.number(cell.gDay),
    );
    return Semantics(
      label: cell.isToday ? '$label، ${loc.trackerDotToday}' : label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cell.isToday
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: cell.isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.4,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.number(cell.hDay),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              loc.number(cell.gDay),
              style: TextStyle(
                fontSize: AppType.micro,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
