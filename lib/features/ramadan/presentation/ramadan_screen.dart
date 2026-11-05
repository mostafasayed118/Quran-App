import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'ramadan_cubit.dart';
import 'ramadan_state.dart';

/// The Ramadan timetable for the selected city.
class RamadanScreen extends StatelessWidget {
  /// Creates the screen.
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<RamadanCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ramadanTitle),
        actions: [
          IconButton(
            tooltip: loc.qadaTitle,
            icon: const Icon(Icons.event_busy),
            onPressed: () => context.push(AppRoutes.qada),
          ),
        ],
      ),
      body: BlocBuilder<RamadanCubit, RamadanState>(
        builder: (context, state) => switch (state) {
          RamadanLoading() => const LoadingView(),
          RamadanFailed() => errorPane(loc, onRetry: cubit.start),
          RamadanReady(:final days) when days.isEmpty =>
            EmptyState(loc.noCity, icon: Icons.location_off_outlined),
          RamadanReady(
            :final monthName,
            :final hijriYear,
            :final days,
            :final today,
          ) =>
            _RamadanList(
              monthName: monthName,
              hijriYear: hijriYear,
              days: days,
              today: today,
            ),
        },
      ),
    );
  }
}

class _RamadanList extends StatelessWidget {
  const _RamadanList({
    required this.monthName,
    required this.hijriYear,
    required this.days,
    required this.today,
  });

  final String monthName;
  final int hijriYear;
  final List<RamadanDay> days;
  final RamadanDay? today;

  @override
  Widget build(BuildContext context) {
    final months = MaterialLocalizations.of(context);
    return ListView.builder(
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      itemCount: days.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _RamadanHeader(
            monthName: monthName,
            hijriYear: hijriYear,
            today: today,
            firstDay: days.first,
            months: months,
          );
        }
        if (index == 1) return const _TableHeader();
        return _DayRow(day: days[index - 2], months: months);
      },
    );
  }
}

class _RamadanHeader extends StatelessWidget {
  const _RamadanHeader({
    required this.monthName,
    required this.hijriYear,
    required this.today,
    required this.firstDay,
    required this.months,
  });

  final String monthName;
  final int hijriYear;
  final RamadanDay? today;
  final RamadanDay firstDay;
  final MaterialLocalizations months;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final anchor = today ?? firstDay;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$monthName ${loc.number(hijriYear)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              today == null
                  ? loc.ramadanStartsOn(
                      months.formatMediumDate(firstDay.date),
                    )
                  : loc.ramadanToday(loc.number(today!.hijriDay)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _TimePill(
                    label: loc.ramadanImsak,
                    time: anchor.imsak,
                  ),
                ),
                Expanded(
                  child: _TimePill(
                    label: loc.ramadanIftar,
                    time: anchor.iftar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.ramadanImsakNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.time});

  final String label;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          formatHm(time, arabicIndic: loc.usesArabicIndicDigits),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(loc.ramadanDayColumn, style: style)),
          Expanded(
            child: Text(
              loc.ramadanImsak,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              loc.ramadanIftar,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.months});

  final RamadanDay day;
  final MaterialLocalizations months;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: day.isToday ? colors.primaryContainer : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  loc.number(day.hijriDay),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    months.formatMediumDate(day.date),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              formatHm(day.imsak, arabicIndic: loc.usesArabicIndicDigits),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              formatHm(day.iftar, arabicIndic: loc.usesArabicIndicDigits),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
