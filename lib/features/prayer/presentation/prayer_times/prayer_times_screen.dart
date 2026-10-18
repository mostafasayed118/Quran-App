import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'prayer_times_cubit.dart';
import 'prayer_times_state.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  /// W7b (W7a §6): reload in place when the picker returns a selection —
  /// the picker pops `true` on a successful persist; zero state change.
  static Future<void> _openCityPicker(BuildContext context) async {
    final cubit = context.read<PrayerTimesCubit>();
    final reloaded = await context.push<bool>('/prayer-times/city');
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
          PrayerTimesReady() when state.city == null => EmptyState(
              loc.noCity,
              actionLabel: loc.selectCity,
              onAction: () => _openCityPicker(context),
            ),
          PrayerTimesReady() => RefreshIndicator(
              onRefresh: () => context.read<PrayerTimesCubit>().reload(),
              child: _TimesList(state: state),
            ),
        },
      ),
    );
  }
}

class _TimesList extends StatefulWidget {
  const _TimesList({required this.state});

  final PrayerTimesReady state;

  @override
  State<_TimesList> createState() => _TimesListState();
}

class _TimesListState extends State<_TimesList> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      cubit.refreshCountdown();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = widget.state;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                state.city!.nameAr,
                style: const TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 18,
                ),
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
            subtitle: entry.isNext && state.remaining != null
                ? Text(
                    loc.remaining(formatDurationHm(state.remaining!)),
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
