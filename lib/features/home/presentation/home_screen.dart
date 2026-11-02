import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/routing/route_observer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/service_tile.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_cubit.dart';
import 'home_state.dart';

/// The dashboard.
///
/// Structure, in the order the eye should read it:
///   1. the next prayer (countdown first — it is the one number that changes),
///   2. where the reader left off,
///   3. the services, grouped by intent instead of one undifferentiated grid.
///
/// Every destination that existed before this layout still exists; grouping
/// only changes where a tile sits.
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
          HomeFailed() => errorPane(
              loc,
              onRetry: () => context.read<HomeCubit>().reload(),
            ),
          HomeReady(:final lastRead, :final nextPrayer, :final showSetup) =>
            ListView(
              padding: appScrollPadding(
                context,
                const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
              ),
              children: [
                // One Column child rather than a lazy list: the dashboard is a
                // fixed 14 tiles plus three cards, and eager building keeps
                // every label reachable at a 2.0 text scale.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showSetup) ...[
                      const _SetupCard(),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (lastRead != null)
                      _ContinueReadingCard(lastRead: lastRead),
                    if (lastRead != null) const SizedBox(height: AppSpacing.sm),
                    if (nextPrayer != null)
                      _NextPrayerCard(prayer: nextPrayer)
                    else
                      const _NoCityCard(),
                    SectionHeader(title: loc.homeSectionQuran, inset: 0),
                    const _ServiceGrid(services: _quranServices),
                    SectionHeader(title: loc.homeSectionWorship, inset: 0),
                    const _ServiceGrid(services: _worshipServices),
                    SectionHeader(title: loc.homeSectionMore, inset: 0),
                    const _ServiceGrid(services: _moreServices),
                  ],
                ),
              ],
            ),
        },
      ),
    );
  }
}

/// Direction-aware disclosure chevron.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? Icons.chevron_left
          : Icons.chevron_right,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// A 44 dp tinted circle that gives an icon a place to sit.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.gold = false});

  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = gold ? colors.secondary : colors.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: AppColors.badgeTintAlpha),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.lastRead});

  final LastReadCard lastRead;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(quranReaderPath(
          surah: lastRead.surahId,
          ayah: lastRead.ayahNumber,
        )),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const _IconBadge(icon: Icons.menu_book_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastRead.surahName,
                      style: AppTheme.meQuranHead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.continueReadingAyah(
                          lastRead.ayahNumber.toArabicIndic),
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const _Chevron(),
            ],
          ),
        ),
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
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(AppRoutes.prayerTimes),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconBadge(icon: Icons.schedule, gold: true),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      loc.nextPrayer,
                      style: AppTheme.caption.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const _Chevron(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.name.label(loc),
                          style: AppTheme.heroTitle
                              .copyWith(color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Time and city travel together so the block reads
                        // "name, at this time, in this place" at a glance.
                        Wrap(
                          spacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              formatHm(prayer.time),
                              style: AppTheme.caption.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: colors.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                            Text(
                              prayer.cityName,
                              style: AppTheme.caption.copyWith(
                                color: colors.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // The countdown is the one number that moves; it gets the
                  // opposite side of the card so the eye can find it without
                  // scanning. It only scales down when a 2.0 text scale would
                  // otherwise break the row.
                  Flexible(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: _LiveCountdown(target: prayer.time),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts down to [target] once a second.
///
/// Kept as its own widget so the tick rebuilds one text line instead of the
/// whole dashboard. The timer is cancelled with the widget; the parent cubit
/// reloads the card when the prayer actually passes.
class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown({required this.target});

  final DateTime target;

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      formatDurationHms(widget.target.difference(DateTime.now())),
      style: AppTheme.heroValue.copyWith(color: colors.onPrimaryContainer),
      maxLines: 2,
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(AppRoutes.onboarding),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.checklist_rtl, color: colors.onPrimaryContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.homeSetupTitle, style: AppTheme.cardTitle),
                    const SizedBox(height: 2),
                    Text(loc.homeSetupBody,
                        style: AppTheme.mutedFootnote(context)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: colors.onPrimaryContainer),
            ],
          ),
        ),
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
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => HomeScreen._openCityPicker(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const _IconBadge(icon: Icons.location_on_outlined, gold: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.selectCity, style: AppTheme.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      loc.noCity,
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const _Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});

  final List<_Service> services;

  /// Three columns, chunked into rows.
  ///
  /// A `Wrap` lets every tile size itself, which leaves the short labels
  /// floating above the baseline of the long ones. `IntrinsicHeight` gives
  /// each row one height, so the tile bottoms line up without capping the
  /// label (the old grid capped it with `maxLines: 2` + ellipsis).
  @override
  Widget build(BuildContext context) {
    const gap = AppSpacing.sm;
    const columns = 3;
    final loc = AppLocalizations.of(context);
    final rows = <List<_Service>>[
      for (var i = 0; i < services.length; i += columns)
        services.sublist(
          i,
          i + columns > services.length ? services.length : i + columns,
        ),
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  if (c < rows[r].length)
                    Expanded(
                      child: ServiceTile(
                        icon: rows[r][c].icon,
                        label: rows[r][c].label(loc),
                        onTap: () => context.push(rows[r][c].route),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

typedef _Service = ({
  IconData icon,
  String Function(AppLocalizations) label,
  String route
});

const List<_Service> _quranServices = [
  (icon: Icons.menu_book, label: _locQuran, route: AppRoutes.quran),
  (icon: Icons.graphic_eq, label: _locRecitations, route: AppRoutes.recitation),
  (
    icon: Icons.bookmarks_outlined,
    label: _locBookmarks,
    route: AppRoutes.bookmarks
  ),
];

const List<_Service> _worshipServices = [
  (icon: Icons.schedule, label: _locPrayerTimes, route: AppRoutes.prayerTimes),
  (icon: Icons.explore, label: _locQibla, route: AppRoutes.qibla),
  (icon: Icons.spa, label: _locAzkar, route: AppRoutes.azkar),
  (
    icon: Icons.radio_button_checked,
    label: _locTasbih,
    route: AppRoutes.tasbih
  ),
  (icon: Icons.volunteer_activism, label: _locDuas, route: AppRoutes.duas),
  (icon: Icons.mosque, label: _locWorship, route: AppRoutes.worship),
];

const List<_Service> _moreServices = [
  (icon: Icons.library_books, label: _locLibrary, route: AppRoutes.library),
  (icon: Icons.payments_outlined, label: _locZakat, route: AppRoutes.zakat),
  (icon: Icons.calendar_month, label: _locHijri, route: AppRoutes.hijri),
  (icon: Icons.auto_awesome, label: _locAsma, route: AppRoutes.asma),
  (icon: Icons.settings, label: _locSettings, route: AppRoutes.settings),
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
