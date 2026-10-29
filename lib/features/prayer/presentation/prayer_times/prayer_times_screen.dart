import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'prayer_times_cubit.dart';
import 'prayer_times_state.dart';

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
            tooltip: loc.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PrayerTimesCubit>().reload(),
          ),
        ],
      ),
      body: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) => switch (state) {
          PrayerTimesLoading() => const LoadingView(),
          PrayerTimesFailed() => errorPane(loc),
          PrayerTimesReady(:final city?) => RefreshIndicator(
              onRefresh: () => context.read<PrayerTimesCubit>().reload(),
              child: _TimesList(state: state, city: city),
            ),
          PrayerTimesReady() => EmptyState(
              loc.noCity,
              actionLabel: loc.selectCity,
              onAction: () => _openCityPicker(context),
            ),
        },
      ),
    );
  }
}

class _TimesList extends StatefulWidget {
  const _TimesList({required this.state, required this.city});

  final PrayerTimesReady state;
  final City city;

  @override
  State<_TimesList> createState() => _TimesListState();
}

class _TimesListState extends State<_TimesList> with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  void _startTicker() {
    if (_ticker != null) return;
    final cubit = context.read<PrayerTimesCubit>();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      cubit.refreshCountdown();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopTicker();
      case AppLifecycleState.resumed:
        _startTicker();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = widget.state;
    final city = widget.city;
    return ListView.builder(
      padding: appScrollPadding(context, const EdgeInsets.all(AppSpacing.md)),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.entries.length + 1,
      itemBuilder: (context, i) {
        final remaining = state.remaining;
        if (i == 0) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                city.nameAr,
                style: AppTheme.meQuranTitle,
              ),
              trailing: IconButton(
                tooltip: loc.selectCity,
                icon: const Icon(Icons.edit),
                onPressed: () => PrayerTimesScreen._openCityPicker(context),
              ),
            ),
          );
        }
        final entry = state.entries[i - 1];
        return Card(
          color: entry.isNext ? colors.primaryContainer : null,
          child: ListTile(
            leading: Icon(
              entry.isNext ? Icons.schedule : Icons.radio_button_unchecked,
              color: entry.isNext ? colors.onPrimaryContainer : colors.outline,
            ),
            title: Text(
              entry.name.label(loc),
              style: TextStyle(
                fontWeight: entry.isNext ? FontWeight.bold : null,
              ),
            ),
            subtitle: entry.isNext && remaining != null
                ? Text(
                    loc.remaining(formatDurationHm(remaining)),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onPrimaryContainer,
                    ),
                  )
                : null,
            trailing: Text(
              formatHm(entry.time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: entry.isNext ? FontWeight.bold : null,
                color: entry.isNext ? colors.onPrimaryContainer : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
