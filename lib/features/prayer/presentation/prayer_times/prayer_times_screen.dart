import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/prayer_time_service.dart';
import 'prayer_times_cubit.dart';
import 'prayer_times_state.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.prayerTimes)),
      body: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) => switch (state) {
          PrayerTimesLoading() => const LoadingView(),
          PrayerTimesReady() when state.city == null => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.noCity),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/prayer-times/city'),
                    child: Text(loc.selectCity),
                  ),
                ],
              ),
            ),
          PrayerTimesReady() => _TimesList(state: state),
        },
      ),
    );
  }
}

class _TimesList extends StatelessWidget {
  const _TimesList({required this.state});

  final PrayerTimesReady state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    String label(PrayerName name) => switch (name) {
          PrayerName.fajr => loc.fajr,
          PrayerName.sunrise => loc.sunrise,
          PrayerName.dhuhr => loc.dhuhr,
          PrayerName.asr => loc.asr,
          PrayerName.maghrib => loc.maghrib,
          PrayerName.isha => loc.isha,
        };
    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/prayer-times/city'),
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
              label(entry.name),
              style: TextStyle(
                fontWeight: entry.isNext ? FontWeight.bold : null,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatHm(entry.time),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: entry.isNext ? FontWeight.bold : null,
                    color:
                        entry.isNext ? colors.onPrimaryContainer : null,
                  ),
                ),
                if (entry.isNext && state.remaining != null)
                  Text(
                    loc.remaining(formatDurationHm(state.remaining!)),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
