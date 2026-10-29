import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/routing/route_observer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_cubit.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Same contract as the prayer-times screen: the picker pops `true` on a
  /// successful persist, and Home reloads so the next-prayer card appears.
  static Future<void> _openCityPicker(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final reloaded = await context.push<bool>(AppRoutes.cityPicker);
    if (reloaded == true && context.mounted) {
      await cubit.reload();
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, WidgetsBindingObserver {
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    unawaited(context.read<HomeCubit>().reload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<HomeCubit>().reload());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.appName)),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state) {
          HomeLoading() => const LoadingView(),
          HomeFailed() => errorPane(loc),
          HomeReady(:final lastRead, :final nextPrayer) => ListView(
              padding: appScrollPadding(
                  context, const EdgeInsets.all(AppSpacing.md)),
              children: [
                if (lastRead != null) _LastReadCard(lastRead: lastRead),
                if (nextPrayer != null)
                  _NextPrayerCard(prayer: nextPrayer)
                else
                  const _NoCityCard(),
                const SizedBox(height: AppSpacing.sm),
                const _FeatureGrid(),
              ],
            ),
        },
      ),
    );
  }
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard({required this.lastRead});

  final LastReadCard lastRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.menu_book, color: colors.primary),
        title: Text(
          lastRead.surahName,
          style: AppTheme.meQuranHead,
        ),
        subtitle: Text(
          loc.continueReadingAyah(lastRead.ayahNumber.toArabicIndic),
        ),
        onTap: () => context.push(quranReaderPath(
          surah: lastRead.surahId,
          ayah: lastRead.ayahNumber,
        )),
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.prayer});

  final NextPrayerCard prayer;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.schedule, color: colors.secondary),
        title: Text(prayer.name.label(loc)),
        subtitle: Text(loc.nextPrayer),
        trailing: Text(
          formatHm(prayer.time),
          style: AppTheme.rowTitle,
        ),
        onTap: () => context.push(AppRoutes.prayerTimes),
      ),
    );
  }
}

class _NoCityCard extends StatelessWidget {
  const _NoCityCard();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: colors.secondary,
        ),
        title: Text(loc.selectCity),
        subtitle: Text(loc.noCity),
        onTap: () => HomeScreen._openCityPicker(context),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
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
    );
  }
}

typedef _Feature = (IconData, String Function(AppLocalizations), String);

const List<_Feature> _features = [
  (Icons.menu_book, _locQuran, AppRoutes.quran),
  (Icons.schedule, _locPrayerTimes, AppRoutes.prayerTimes),
  (Icons.explore, _locQibla, AppRoutes.qibla),
  (Icons.graphic_eq, _locRecitations, AppRoutes.recitation),
  (Icons.library_books, _locLibrary, AppRoutes.library),
  (Icons.spa, _locAzkar, AppRoutes.azkar),
  (Icons.radio_button_checked, _locTasbih, AppRoutes.tasbih),
  (Icons.volunteer_activism, _locDuas, AppRoutes.duas),
  (Icons.mosque, _locWorship, AppRoutes.worship),
  (Icons.payments_outlined, _locZakat, AppRoutes.zakat),
  (Icons.calendar_month, _locHijri, AppRoutes.hijri),
  (Icons.auto_awesome, _locAsma, AppRoutes.asma),
  (Icons.bookmarks_outlined, _locBookmarks, AppRoutes.bookmarks),
  (Icons.settings, _locSettings, AppRoutes.settings),
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

String _locBookmarks(AppLocalizations loc) => loc.bookmarks;

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
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest
              .withValues(alpha: AppColors.mutedSurfaceAlpha),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
