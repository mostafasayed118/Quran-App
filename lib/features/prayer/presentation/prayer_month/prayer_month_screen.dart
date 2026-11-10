import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'prayer_month_cubit.dart';
import 'prayer_month_state.dart';

/// A read-only month of prayer times for the selected city.
class PrayerMonthScreen extends StatelessWidget {
  /// Creates the screen.
  const PrayerMonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<PrayerMonthCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.monthlyTimetable),
        actions: [
          IconButton(
            tooltip: loc.previousMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: cubit.previousMonth,
          ),
          IconButton(
            tooltip: loc.nextMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: cubit.nextMonth,
          ),
        ],
      ),
      body: AppContentFrame(
        child: BlocBuilder<PrayerMonthCubit, PrayerMonthState>(
          builder: (context, state) => switch (state) {
            PrayerMonthLoading() => const LoadingView(),
            PrayerMonthFailed() => errorPane(loc, onRetry: cubit.start),
            PrayerMonthReady(:final city, :final days)
                when city == null || days.isEmpty =>
              EmptyState(loc.noCity, icon: Icons.location_off_outlined),
            PrayerMonthReady(:final year, :final month, :final days) =>
              _MonthList(year: year, month: month, days: days),
          },
        ),
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  const _MonthList({
    required this.year,
    required this.month,
    required this.days,
  });

  final int year;
  final int month;
  final List<PrayerMonthDay> days;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final months = MaterialLocalizations.of(context);
    return ListView.builder(
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      itemCount: days.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              months.formatMonthYear(DateTime(year, month)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          );
        }
        final day = days[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                months.formatMediumDate(day.date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final prayer in day.prayers)
                    Text(
                      '${prayer.name.label(loc)} ${formatHm(prayer.time, arabicIndic: loc.usesArabicIndicDigits)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}
