import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/next_prayer_focus.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/routing/route_observer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/city_clock.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/lifecycle_ticker.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/service_tile.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_cubit.dart';
import 'home_state.dart';

part 'home_cards.dart';
part 'home_services.dart';

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
  GoRouter? _router;
  String? _lastLocation;

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
    final router = GoRouter.maybeOf(context);
    if (router != _router) {
      _router?.routerDelegate.removeListener(_onLocationChanged);
      _router = router;
      // Seeded, not fired: the cubit's own start() already loaded this screen.
      _lastLocation = router == null ? null : _locationOf(router);
      router?.routerDelegate.addListener(_onLocationChanged);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onLocationChanged);
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The location the router shows, including an imperatively pushed route.
  ///
  /// `currentConfiguration.uri` deliberately leaves out `ImperativeRouteMatch`s
  /// (go_router 18), and the reader is pushed above the shell, so that member
  /// would still read `/home` for the whole round trip. The delegate's
  /// top-most state is the one that actually moves.
  String? _locationOf(GoRouter router) {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return null;
    return router.state.uri.path;
  }

  /// Reloads when the router lands back on Home from somewhere else.
  ///
  /// Home subscribes to the inner route, while the reader is a root-level
  /// route above the shell, so `didPopNext` never reaches this screen: the
  /// location is the one re-entry signal that crosses the navigator boundary.
  void _onLocationChanged() {
    final router = _router;
    if (router == null) return;
    final location = _locationOf(router);
    if (location == null || location == _lastLocation) return;
    final previous = _lastLocation;
    _lastLocation = location;
    if (location == AppRoutes.home && previous != AppRoutes.home && mounted) {
      unawaited(context.read<HomeCubit>().reload());
    }
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
      body: AppContentFrame(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => switch (state) {
            HomeLoading() => const LoadingView(),
            HomeFailed() => errorPane(
                loc,
                onRetry: () => context.read<HomeCubit>().reload(),
              ),
            HomeReady(
              :final lastRead,
              :final nextPrayer,
              :final cityTimezone,
              :final cityNameEn,
            ) =>
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
                      if (nextPrayer != null)
                        _TodayPanel(
                          lastRead: lastRead,
                          prayer: nextPrayer,
                          timezone: cityTimezone,
                          cityNameEn: cityNameEn,
                        )
                      else ...[
                        if (lastRead != null)
                          _ContinueReadingCard(lastRead: lastRead),
                        if (lastRead != null)
                          const SizedBox(height: AppSpacing.sm),
                        const _NoCityCard(),
                      ],
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
      ),
    );
  }
}
