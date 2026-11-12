import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/adhan_player.dart';
import '../core/domain/adhan_preferences.dart';
import '../core/domain/ayah_batch_lookup.dart';
import '../core/domain/ayah_lookup.dart';
import '../core/domain/city.dart';
import '../core/domain/last_read.dart';
import '../core/domain/onboarding_status.dart';
import '../core/domain/prayer_config.dart';
import '../core/domain/prayer_times.dart';
import '../core/domain/pre_adhan_canceller.dart';
import '../core/domain/quran_limits.dart';
import '../core/domain/ramadan_calendar.dart';
import '../core/domain/reminder_diagnostics.dart';
import '../core/domain/reminders.dart';
import '../core/domain/store_listing.dart';
import '../core/domain/version_policy.dart';
import '../core/l10n/app_locale_controller.dart';
import '../core/platform/home_widget_updater.dart';
import '../core/routing/route_cubit_scope.dart';
import '../core/theme/app_theme_controller.dart';
import '../core/utils/app_routes.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/asma/data/asma_repository.dart';
import '../features/asma/presentation/asma_cubit.dart';
import '../features/asma/presentation/asma_screen.dart';
import '../features/azkar/data/azkar_repository.dart';
import '../features/azkar/data/azkar_saved_state.dart';
import '../features/azkar/presentation/azkar_cubit.dart';
import '../features/azkar/presentation/azkar_screen.dart';
import '../features/backup/data/backup_service.dart';
import '../features/backup/presentation/backup_cubit.dart';
import '../features/backup/presentation/backup_section.dart';
import '../features/duas/data/dua_repository.dart';
import '../features/duas/data/ruqyah_repository.dart';
import '../features/duas/presentation/duas_cubit.dart';
import '../features/duas/presentation/duas_screen.dart';
import '../features/hijri/data/hijri_offset_source.dart';
import '../features/hijri/data/hijri_service.dart';
import '../features/hijri/presentation/hijri_cubit.dart';
import '../features/hijri/presentation/hijri_screen.dart';
import '../features/home/presentation/home_cubit.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/library/data/catalog_repository.dart';
import '../features/library/data/hadith_personal.dart';
import '../features/library/data/pack_downloader.dart';
import '../features/library/data/translation_search_source.dart';
import '../features/library/presentation/hadith/hadith_cubit.dart';
import '../features/library/presentation/hadith/hadith_screen.dart';
import '../features/library/presentation/library_cubit.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/library/presentation/search/translation_search_cubit.dart';
import '../features/library/presentation/search/translation_search_screen.dart';
import '../features/onboarding/presentation/onboarding_cubit.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/prayer/data/city_repository.dart';
import '../features/prayer/data/location_service.dart';
import '../features/prayer/presentation/city_picker/city_picker_cubit.dart';
import '../features/prayer/presentation/city_picker/city_picker_screen.dart';
import '../features/prayer/presentation/prayer_config/prayer_config_cubit.dart';
import '../features/prayer/presentation/prayer_config/prayer_config_screen.dart';
import '../features/prayer/presentation/prayer_month/prayer_month_cubit.dart';
import '../features/prayer/presentation/prayer_month/prayer_month_screen.dart';
import '../features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import '../features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import '../features/qibla/data/compass_calibration.dart';
import '../features/qibla/data/heading_service.dart';
import '../features/qibla/data/qibla_service.dart';
import '../features/qibla/presentation/qibla_cubit.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../features/quran/data/ayah_repository.dart';
import '../features/quran/data/bookmark_meta.dart';
import '../features/quran/data/juz_index_source.dart';
import '../features/quran/data/last_read_repository.dart';
import '../features/quran/data/page_anchor_source.dart';
import '../features/quran/data/reader_layout_source.dart';
import '../features/quran/data/reader_settings_source.dart';
import '../features/quran/data/surah_source.dart';
import '../features/quran/data/uthmani_text_source.dart';
import '../features/quran/domain/quran_search_source.dart';
import '../features/quran/presentation/bookmarks/bookmark_meta_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_screen.dart';
import '../features/quran/presentation/bookmarks/folder_bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/folder_bookmarks_screen.dart';
import '../features/quran/presentation/index/juz_index_cubit.dart';
import '../features/quran/presentation/index/juz_index_screen.dart';
import '../features/quran/presentation/index/surah_index_cubit.dart';
import '../features/quran/presentation/reader/reader_cubit.dart';
import '../features/quran/presentation/reader/reader_route_scope.dart';
import '../features/quran/presentation/reader/reader_screen.dart';
import '../features/quran/presentation/search/quran_search_cubit.dart';
import '../features/quran/presentation/search/quran_search_screen.dart';
import '../features/quran/presentation/workspace/quran_tab_screen.dart';
import '../features/ramadan/data/qada_source.dart';
import '../features/ramadan/presentation/qada_cubit.dart';
import '../features/ramadan/presentation/qada_screen.dart';
import '../features/ramadan/presentation/ramadan_cubit.dart';
import '../features/ramadan/presentation/ramadan_screen.dart';
import '../features/recitation/data/reciter_repository.dart';
import '../features/recitation/presentation/downloads/downloads_cubit.dart';
import '../features/recitation/presentation/downloads/downloads_screen.dart';
import '../features/recitation/presentation/packs/reciter_packs_screen.dart';
import '../features/recitation/presentation/playback/playback_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import '../features/recitation/presentation/reciters/reciters_cubit.dart';
import '../features/recitation/presentation/reciters/reciters_screen.dart';
import '../features/settings/presentation/adhan_picker_cubit.dart';
import '../features/settings/presentation/adhan_picker_screen.dart';
import '../features/settings/presentation/principles_screen.dart';
import '../features/settings/presentation/settings_cubit.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasbih/data/tasbih_repository.dart';
import '../features/tasbih/presentation/tasbih_cubit.dart';
import '../features/tasbih/presentation/tasbih_screen.dart';
import '../features/tracker/data/khatma_repository.dart';
import '../features/tracker/data/prayer_log_repository.dart';
import '../features/tracker/presentation/tracker_cubit.dart';
import '../features/tracker/presentation/tracker_screen.dart';
import '../features/update/presentation/update_gate_screen.dart';
import '../features/zakat/presentation/zakat_cubit.dart';
import '../features/zakat/presentation/zakat_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_shell.dart';
import 'di/injector.dart';
import 'onboarding_gate.dart';
import 'route_observer.dart';
import 'version_gate.dart';

part 'routes/read_routes.dart';
part 'routes/recitation_routes.dart';
part 'routes/settings_routes.dart';
part 'routes/worship_routes.dart';

abstract final class AppRouter {
  /// The first-run gate shared with the router (`refreshListenable`) and the
  /// onboarding flow (it is the app's `OnboardingStatusSource`).
  static final OnboardingGate onboardingGate = OnboardingGate();

  /// The update gate (fail-open). The redirect needs the answer synchronously,
  /// so the verdict is cached here and the router re-evaluates when it lands.
  static final VersionGate versionGate = VersionGate();

  /// The redirect for [location]; null keeps the requested route.
  ///
  /// Onboarding decides first (a first-run user must reach the flow), then the
  /// update gate. The mandatory policy is evaluated only on the routes an
  /// onboarded user can reach: it deliberately does not interrupt the first-run
  /// flow, because updating before onboarding would strand a new user on a
  /// screen whose only action leaves the app.
  static String? redirectFor(String location) {
    final onboarding = onboardingGate.decide(location);
    if (onboarding != null) return onboarding;
    return versionGate.decide(location);
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    observers: [appRouteObserver],
    refreshListenable:
        Listenable.merge(<Listenable>[onboardingGate, versionGate]),
    redirect: (_, state) => redirectFor(state.matchedLocation),
    errorBuilder: (context, state) {
      final loc = AppLocalizations.of(context);
      return PlaceholderScreen(
        title: loc.pageNotFound,
        hint: loc.pageNotFoundHint,
        actionLabel: loc.home,
        onAction: () => context.go(AppRoutes.home),
      );
    },
    routes: [
      _shellRoute(),
      ..._postShellRoutes(),
    ],
  );

  static RouteBase _shellRoute() {
    return ShellRoute(
      builder: (context, state, child) => BlocProvider<PlaybackCubit>.value(
        // The player is an app-level singleton (registered in DI) so the
        // mini player can live above the tabs instead of inside the reader.
        value: getIt<PlaybackCubit>(),
        child: AppShell(
          location: state.uri.path,
          child: child,
        ),
      ),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => RouteCubitScope<HomeCubit>(
            create: () => HomeCubit(
              lastRead: getIt<LastReadMarker>(),
              ayahs: getIt<AyahLookup>(),
              prayer: getIt<PrayerTimesPort>(),
              city: getIt<CitySource>(),
              configChanges: getIt<PrayerConfigSource>().changes,
              widgetUpdater: getIt<HomeWidgetUpdater>(),
            ),
            identity: AppRoutes.home,
            start: (cubit) => cubit.start(),
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, __) => RouteCubitScope<SurahIndexCubit>(
            create: () => SurahIndexCubit(getIt<SurahSource>()),
            identity: AppRoutes.quran,
            start: (cubit) => cubit.start(),
            child: QuranTabScreen(
              createReader: _createReader,
              createJuz: () => JuzIndexCubit(source: getIt<JuzIndexSource>()),
              createBookmarks: () => BookmarksCubit(
                getIt<AyahRepository>(),
                pager: getIt<AyahRepository>(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.juzIndex,
          builder: (_, __) => RouteCubitScope<JuzIndexCubit>(
            create: () => JuzIndexCubit(source: getIt<JuzIndexSource>()),
            identity: AppRoutes.juzIndex,
            start: (cubit) => cubit.start(),
            child: const JuzIndexScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.prayerTimes,
          builder: (_, __) => RouteCubitScope<PrayerTimesCubit>(
            create: () => PrayerTimesCubit(
              prayer: getIt<PrayerTimesPort>(),
              city: getIt<CitySource>(),
              settings: getIt<ReminderSettingsPort>(),
              scheduler: getIt<ReminderSchedulerPort>(),
              configChanges: getIt<PrayerConfigSource>().changes,
            ),
            identity: AppRoutes.prayerTimes,
            start: (cubit) => cubit.start(),
            child: const PrayerTimesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.azkar,
          builder: (_, __) => RouteCubitScope<AzkarCubit>(
            create: () => AzkarCubit(
              repository: getIt<AzkarRepository>(),
              savedState: getIt<AzkarSavedStateSource>(),
            ),
            identity: AppRoutes.azkar,
            start: (cubit) => cubit.start(),
            child: const AzkarScreen(),
          ),
        ),
      ],
    );
  }

  /// Every route mounted after the shell.
  ///
  /// <b>Order is behaviour</b>: go_router matches top to bottom, so a group
  /// position here is not style. The spread order below is the order the
  /// method used to hard-code, and the route tests pin the result.
  ///
  /// Split by feature so adding one route is a small edit in a named place
  /// instead of a 410-line method.
  static List<RouteBase> _postShellRoutes() => [
        ..._updateAndSearchRoutes(),
        ..._recitationRoutes(),
        ..._libraryRoutes(),
        ..._prayerRoutes(),
        ..._worshipRoutes(),
        ..._settingsRoutes(),
        ..._readerRoutes(),
        ..._onboardingRoutes(),
        ..._reciterRoutes(),
        ..._bookmarkRoutes(),
      ];
}

/// Builds the reader cubit shared by the full route and the workspace pane.
ReaderCubit _createReader(int surah, int ayah) => ReaderCubit(
      ayahRepository: getIt<AyahRepository>(),
      lastReadRepository: getIt<LastReadRepository>(),
      surahId: surah,
      initialAyah: ayah,
      wirdProgress: getIt<KhatmaRepository>(),
      uthmani: getIt<UthmaniTextSource>(),
      pageAnchors: getIt<PageAnchorSource>(),
      settings: getIt<ReaderSettingsSource>(),
      layout: getIt<ReaderLayoutSource>(),
    );
