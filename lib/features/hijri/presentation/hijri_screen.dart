import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'hijri_cubit.dart';
import 'hijri_state.dart';

class HijriScreen extends StatelessWidget {
  const HijriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.hijriCalendar)),
      body: BlocBuilder<HijriCubit, HijriState>(
        builder: (context, state) => switch (state) {
          HijriLoading() => const LoadingView(),
          HijriFailed() => errorPane(loc),
          HijriReady(
            :final monthName,
            :final year,
            :final offset,
            :final cells,
            :final todayHeader
          ) =>
            ListView(
              padding: appScrollPadding(
                context,
                const EdgeInsets.all(AppSpacing.md),
              ),
              children: [
                _TodayCard(todayHeader: todayHeader),
                _MonthNavBar(monthName: monthName, year: year),
                _MonthGrid(offset: offset, cells: cells),
              ],
            ),
        },
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
              style: AppTheme.meQuranHead,
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
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        IconButton(
          tooltip: loc.nextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => context.read<HijriCubit>().next(),
        ),
        Expanded(
          child: Text(
            loc.hijriDate(monthName, year.toArabicIndic),
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
          icon: const Icon(Icons.chevron_left),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cell.isToday
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.hDay.toArabicIndic,
            style: const TextStyle(
              fontFamily: QuranFonts.meQuran,
              fontSize: 17,
            ),
          ),
          Text(
            cell.gDay.toArabicIndic,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
