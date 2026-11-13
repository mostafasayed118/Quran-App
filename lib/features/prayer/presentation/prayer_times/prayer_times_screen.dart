import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/domain/prayer_name.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/city_clock.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'forbidden_windows_section.dart';
import 'prayer_times_cubit.dart';
import 'prayer_times_state.dart';

part 'prayer_times_list.dart';
part 'prayer_times_cards.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  /// W7b (W7a §6): reload in place when the picker returns a selection —
  /// the picker pops `true` on a successful persist; zero state change.
  static Future<void> _openCityPicker(BuildContext context) async {
    final cubit = context.read<PrayerTimesCubit>();
    final reloaded = await context.push<bool>(AppRoutes.cityPicker);
    if (reloaded == true && context.mounted) {
      await cubit.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.prayerTimes),
        actions: [
          IconButton(
            tooltip: loc.prayerSettings,
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => context.push(AppRoutes.prayerSettings),
          ),
          IconButton(
            tooltip: loc.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PrayerTimesCubit>().reload(),
          ),
        ],
      ),
      body: AppContentFrame.form(
        child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
          builder: (context, state) => switch (state) {
            PrayerTimesLoading() => const LoadingView(),
            PrayerTimesFailed() => errorPane(
                loc,
                onRetry: () => context.read<PrayerTimesCubit>().reload(),
              ),
            PrayerTimesReady(:final city?) => RefreshIndicator(
                onRefresh: () => context.read<PrayerTimesCubit>().reload(),
                child: _TimesList(state: state, city: city),
              ),
            PrayerTimesReady() => EmptyState(
                loc.noCity,
                icon: Icons.location_off_outlined,
                actionLabel: loc.selectCity,
                onAction: () => _openCityPicker(context),
              ),
          },
        ),
      ),
    );
  }
}
