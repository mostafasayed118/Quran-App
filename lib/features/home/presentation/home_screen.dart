import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_cubit.dart';
import 'home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Same contract as the prayer-times screen: the picker pops `true` on a
  /// successful persist, and Home reloads so the next-prayer card appears.
  static Future<void> _openCityPicker(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final reloaded = await context.push<bool>('/prayer-times/city');
    if (reloaded == true && context.mounted) {
      await cubit.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(loc.appName)),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state) {
          HomeLoading() => const LoadingView(),
          HomeFailed() => errorPane(loc, 'home load failed', 'home'),
          HomeReady(:final lastRead, :final nextPrayer) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (lastRead != null)
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.menu_book, color: colors.primary),
                      title: Text(
                        lastRead.surahName,
                        style: AppTheme.meQuranHead,
                      ),
                      subtitle: Text(
                        '﴿${lastRead.ayahNumber.toArabicIndic}﴾ ${loc.continueReading}',
                      ),
                      onTap: () => context.push(
                          '/quran/reader?surah=${lastRead.surahId}&ayah=${lastRead.ayahNumber}'),
                    ),
                  ),
                if (nextPrayer != null)
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: colors.secondary),
                      title: Text(nextPrayer.name.label(loc)),
                      subtitle: Text(loc.nextPrayer),
                      trailing: Text(
                        formatHm(nextPrayer.time),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => context.push('/prayer-times'),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: colors.secondary,
                      ),
                      title: Text(loc.selectCity),
                      subtitle: Text(loc.noCity),
                      onTap: () => _openCityPicker(context),
                    ),
                  ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                  children: [
                    for (final feature in _features)
                      _FeatureTile(
                        icon: feature.$1,
                        label: feature.$2(AppLocalizations.of(context)),
                        onTap: () => context.push(feature.$3),
                      ),
                  ],
                ),
              ],
            ),
        },
      ),
    );
  }
}

typedef _Feature = (IconData, String Function(AppLocalizations), String);

const List<_Feature> _features = [
  (Icons.menu_book, _locQuran, '/quran'),
  (Icons.schedule, _locPrayerTimes, '/prayer-times'),
  (Icons.explore, _locQibla, '/qibla'),
  (Icons.graphic_eq, _locRecitations, '/recitation'),
  (Icons.library_books, _locLibrary, '/library'),
  (Icons.spa, _locAzkar, '/azkar'),
  (Icons.radio_button_checked, _locTasbih, '/tasbih'),
  (Icons.volunteer_activism, _locDuas, '/duas'),
  (Icons.mosque, _locWorship, '/worship'),
  (Icons.payments_outlined, _locZakat, '/zakat'),
  (Icons.calendar_month, _locHijri, '/hijri'),
  (Icons.auto_awesome, _locAsma, '/asma'),
  (Icons.settings, _locSettings, '/settings'),
];

String _locQuran(AppLocalizations loc) => loc.quran;
String _locPrayerTimes(AppLocalizations loc) => loc.prayerTimes;
String _locQibla(AppLocalizations loc) => loc.qibla;
String _locRecitations(AppLocalizations loc) => loc.recitations;
String _locLibrary(AppLocalizations loc) => loc.library;
String _locAzkar(AppLocalizations loc) => loc.azkar;
String _locTasbih(AppLocalizations loc) => loc.tasbih;
String _locDuas(AppLocalizations loc) => loc.duasAndRuqyah;
String _locWorship(AppLocalizations loc) => loc.worshipTracker;
String _locZakat(AppLocalizations loc) => loc.zakat;
String _locHijri(AppLocalizations loc) => loc.hijriCalendar;
String _locAsma(AppLocalizations loc) => loc.asmaUlHusna;
String _locSettings(AppLocalizations loc) => loc.settings;

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
