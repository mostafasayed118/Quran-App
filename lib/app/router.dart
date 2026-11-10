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
  /// update gate (an unsupported install must not run the app). A valid
  /// mandatory policy wins over everything; an absent/invalid one blocks
  /// nothing.
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

  static List<RouteBase> _updateAndSearchRoutes() => [
        GoRoute(
          path: AppRoutes.update,
          // The blocking surface for an unsupported install, or the dismissible
          // optional-update prompt. The mode is read from the gate at build time;
          // the screen receives plain callbacks and never imports the DI root.
          builder: (_, __) {
            final mandatory =
                AppRouter.versionGate.verdict == VersionVerdict.updateRequired;
            return UpdateGateScreen(
              mandatory: mandatory,
              onOpenStore: () => getIt<StoreListingGateway>().open(),
              // Only the recommended (dismissible) surface gets the ack callback.
              onLater: mandatory
                  ? null
                  : () => AppRouter.versionGate.acknowledgeRecommended(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.quranSearch,
          builder: (context, state) => BlocProvider<QuranSearchCubit>(
            create: (_) => QuranSearchCubit(
              getIt<QuranSearchSource>(),
              debounce: const Duration(milliseconds: 300),
            ),
            child: QuranSearchScreen(
              initialQuery: state.uri.queryParameters[AppRouteQuery.q] ?? '',
            ),
          ),
        ),
      ];

  static List<RouteBase> _recitationRoutes() => [
        GoRoute(
          path: AppRoutes.recitation,
          builder: (_, __) => RouteCubitScope<RecitersCubit>(
            create: () => RecitersCubit(repo: getIt<ReciterRepository>()),
            identity: AppRoutes.recitation,
            start: (cubit) => cubit.start(),
            child: const RecitersScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reciterPacks,
          builder: (_, __) => const ReciterPacksScreen(),
        ),
        GoRoute(
          path: AppRoutes.downloads,
          // The cubit is app-scoped on purpose (the queue survives leaving the
          // route); a second instance here would desync its done rows from the
          // per-surah delete affordances.
          builder: (_, __) => BlocProvider<DownloadsCubit>.value(
            value: getIt<DownloadsCubit>(),
            child: const DownloadsScreen(),
          ),
        ),
      ];

  static List<RouteBase> _libraryRoutes() => [
        GoRoute(
          path: AppRoutes.library,
          // A degraded boot registers no PackDownloader (it needs a writable
          // root); the hub has nothing to show then, so it goes home instead of
          // throwing on the missing registration.
          redirect: (_, __) =>
              getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
          builder: (_, __) => RouteCubitScope<LibraryCubit>(
            create: () => LibraryCubit(
              catalog: getIt<CatalogRepository>(),
              downloader: getIt<PackDownloader>(),
            ),
            identity: AppRoutes.library,
            start: (cubit) => cubit.start(),
            child: const LibraryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.hadith,
          // Same degraded-boot guard as /library (the hadith browser reads
          // packs through the downloader).
          redirect: (_, __) =>
              getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
          builder: (context, state) {
            final pack = state.uri.queryParameters[AppRouteQuery.pack] ?? '';
            return RouteCubitScope<HadithCubit>(
              create: () => HadithCubit(
                downloader: getIt<PackDownloader>(),
                packId: pack,
                bookmarks: getIt<HadithBookmarkSource>(),
                positions: getIt<HadithPositionSource>(),
              ),
              identity: pack,
              start: (cubit) => cubit.start(),
              child: const HadithScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.librarySearch,
          redirect: (_, __) =>
              getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
          builder: (_, __) => RouteCubitScope<TranslationSearchCubit>(
            create: () => TranslationSearchCubit(
              source: getIt<TranslationSearchSource>(),
              surahName: (id) async =>
                  (await getIt<AyahLookup>().surahRefById(id))?.nameAr,
            ),
            identity: AppRoutes.librarySearch,
            start: (cubit) => cubit.start(),
            child: const TranslationSearchScreen(),
          ),
        ),
      ];

  static List<RouteBase> _prayerRoutes() => [
        GoRoute(
          path: AppRoutes.cityPicker,
          builder: (_, __) => RouteCubitScope<CityPickerCubit>(
            create: () => CityPickerCubit(
              cityRepo: getIt<CityRepository>(),
              location: getIt<LocationService>(),
            ),
            identity: AppRoutes.cityPicker,
            start: (cubit) => cubit.start(),
            child: const CityPickerScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.prayerSettings,
          builder: (_, __) => RouteCubitScope<PrayerConfigCubit>(
            create: () => PrayerConfigCubit(
              source: getIt<PrayerConfigSource>(),
              preAdhanCanceller: getIt<PreAdhanCanceller>(),
            ),
            identity: AppRoutes.prayerSettings,
            start: (cubit) => cubit.start(),
            child: const PrayerConfigScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.prayerMonth,
          builder: (_, __) => RouteCubitScope<PrayerMonthCubit>(
            create: () => PrayerMonthCubit(
              city: getIt<CitySource>(),
              prayer: getIt<PrayerTimesPort>(),
            ),
            identity: AppRoutes.prayerMonth,
            start: (cubit) => cubit.start(),
            child: const PrayerMonthScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.qibla,
          builder: (_, __) => RouteCubitScope<QiblaCubit>(
            create: () => QiblaCubit(
              city: getIt<CitySource>(),
              qibla: getIt<QiblaService>(),
              heading: getIt<HeadingService>(),
              calibration: getIt<CompassCalibration>(),
            ),
            identity: AppRoutes.qibla,
            start: (cubit) => cubit.start(),
            child: const QiblaScreen(),
          ),
        ),
      ];

  static List<RouteBase> _worshipRoutes() => [
        GoRoute(
          path: AppRoutes.tasbih,
          builder: (_, __) => RouteCubitScope<TasbihCubit>(
            create: () => TasbihCubit(repo: getIt<TasbihRepository>()),
            identity: AppRoutes.tasbih,
            start: (cubit) => cubit.start(),
            child: const TasbihScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.duas,
          builder: (_, __) => RouteCubitScope<DuasCubit>(
            create: () => DuasCubit(
              duas: getIt<DuaRepository>(),
              ruqyah: getIt<RuqyahRepository>(),
              ayahs: getIt<AyahLookup>(),
            ),
            identity: AppRoutes.duas,
            start: (cubit) => cubit.start(),
            child: const DuasScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.worship,
          builder: (_, __) => RouteCubitScope<TrackerCubit>(
            create: () => TrackerCubit(
              repo: getIt<PrayerLogRepository>(),
              khatma: getIt<KhatmaRepository>(),
            ),
            identity: AppRoutes.worship,
            start: (cubit) => cubit.start(),
            child: const TrackerScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.ramadan,
          builder: (_, __) => RouteCubitScope<RamadanCubit>(
            create: () => RamadanCubit(
              city: getIt<CitySource>(),
              prayer: getIt<PrayerTimesPort>(),
              calendar: getIt<RamadanCalendar>(),
            ),
            identity: AppRoutes.ramadan,
            start: (cubit) => cubit.start(),
            child: const RamadanScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.qada,
          builder: (_, __) => RouteCubitScope<QadaCubit>(
            create: () => QadaCubit(source: getIt<QadaSource>()),
            identity: AppRoutes.qada,
            start: (cubit) => cubit.start(),
            child: const QadaScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.zakat,
          builder: (_, __) => BlocProvider<ZakatCubit>(
            create: (_) => ZakatCubit(),
            child: const ZakatScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.hijri,
          builder: (_, __) => RouteCubitScope<HijriCubit>(
            create: () => HijriCubit(
              service: getIt<HijriService>(),
              offset: getIt<HijriOffsetSource>(),
            ),
            identity: AppRoutes.hijri,
            start: (cubit) => cubit.start(),
            child: const HijriScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.asma,
          builder: (_, __) => RouteCubitScope<AsmaCubit>(
            create: () => AsmaCubit(repository: getIt<AsmaRepository>()),
            identity: AppRoutes.asma,
            start: (cubit) => cubit.start(),
            child: const AsmaScreen(),
          ),
        ),
      ];

  static List<RouteBase> _settingsRoutes() => [
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider<BackupCubit>(
                create: (_) => BackupCubit(service: getIt<BackupService>()),
              ),
            ],
            child: RouteCubitScope<SettingsCubit>(
              create: () => SettingsCubit(
                settings: getIt<ReminderSettingsPort>(),
                prayerSettings: getIt<PrayerReminderSettingsPort>(),
                city: getIt<CitySource>(),
                prayer: getIt<PrayerTimesPort>(),
                scheduler: getIt<ReminderSchedulerPort>(),
                adhanPrefs: getIt<AdhanPreferences>(),
              ),
              identity: AppRoutes.settings,
              start: (cubit) => cubit.start(),
              child: SettingsScreen(
                backupSection: const BackupSection(),
                locale: getIt<AppLocaleController>(),
                theme: getIt<AppThemeController>(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.adhanPicker,
          builder: (_, __) => RouteCubitScope<AdhanPickerCubit>(
            create: () => AdhanPickerCubit(
              prefs: getIt<AdhanPreferences>(),
              player: getIt<AdhanPlayer>(),
              // The picker only needs "the schedule changed", not the city and
              // prayer machinery behind it.
              reschedule: () => getIt<ReminderSettingsPort>().reschedule(
                city: getIt<CitySource>(),
                prayer: getIt<PrayerTimesPort>(),
                scheduler: getIt<ReminderSchedulerPort>(),
              ),
            ),
            identity: AppRoutes.adhanPicker,
            start: (cubit) => cubit.start(),
            child: const AdhanPickerScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.principles,
          builder: (_, __) => const PrinciplesScreen(),
        ),
      ];

  static List<RouteBase> _readerRoutes() => [
        GoRoute(
          path: AppRoutes.reader,
          builder: (context, state) {
            final surah = (int.tryParse(
                        state.uri.queryParameters[AppRouteQuery.surah] ?? '') ??
                    kFirstSurahId)
                .clamp(kFirstSurahId, kSurahCount);
            final ayahParam = int.tryParse(
                    state.uri.queryParameters[AppRouteQuery.ayah] ?? '') ??
                0;
            final ayah = ayahParam < 0 ? 0 : ayahParam;
            return MultiBlocProvider(
              providers: [
                BlocProvider<PlaybackCubit>.value(
                  value: getIt<PlaybackCubit>(),
                ),
              ],
              child: ReaderRouteScope(
                surah: surah,
                ayah: ayah,
                create: () => _createReader(surah, ayah),
                child: const ReaderScreen(),
              ),
            );
          },
        ),
      ];

  static List<RouteBase> _onboardingRoutes() => [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => RouteCubitScope<OnboardingCubit>(
            create: () => OnboardingCubit(
              city: getIt<CitySource>(),
              status: getIt<OnboardingStatusSource>(),
              reminders: getIt<ReminderSchedulerPort>(),
            ),
            identity: AppRoutes.onboarding,
            start: (cubit) => cubit.start(),
            child: const OnboardingScreen(),
          ),
          routes: [
            GoRoute(
              path: 'city',
              builder: (_, __) => RouteCubitScope<CityPickerCubit>(
                create: () => CityPickerCubit(
                  cityRepo: getIt<CityRepository>(),
                  location: getIt<LocationService>(),
                ),
                identity: AppRoutes.onboardingCity,
                start: (cubit) => cubit.start(),
                child: const CityPickerScreen(),
              ),
            ),
          ],
        ),
      ];

  static List<RouteBase> _reciterRoutes() => [
        GoRoute(
          path: AppRoutes.reciter,
          builder: (context, state) {
            final row = state.uri.queryParameters[AppRouteQuery.row] ?? '';
            return MultiBlocProvider(
              providers: [
                BlocProvider<PlaybackCubit>.value(
                  value: getIt<PlaybackCubit>(),
                ),
                BlocProvider<DownloadsCubit>.value(
                  value: getIt<DownloadsCubit>(),
                ),
              ],
              child: RouteCubitScope<ReciterSurahsCubit>(
                identity: row,
                create: () => ReciterSurahsCubit(
                  reciters: getIt<ReciterRepository>(),
                  downloads: getIt<DownloadsCubit>(),
                  rowId: row,
                ),
                start: (cubit) => cubit.start(),
                child: const ReciterSurahsScreen(),
              ),
            );
          },
        ),
      ];

  static List<RouteBase> _bookmarkRoutes() => [
        GoRoute(
          path: AppRoutes.bookmarks,
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider<BookmarkMetaCubit>(
                create: (_) =>
                    BookmarkMetaCubit(source: getIt<BookmarkMetaSource>())
                      ..start(),
              ),
            ],
            child: RouteCubitScope<BookmarksCubit>(
              create: () => BookmarksCubit(
                getIt<AyahRepository>(),
                pager: getIt<AyahRepository>(),
              ),
              identity: AppRoutes.bookmarks,
              start: (cubit) => cubit.start(),
              child: const BookmarksScreen(showMeta: true),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookmarksFolder,
          builder: (context, state) {
            final folder = state.uri.queryParameters[AppRouteQuery.name] ?? '';
            return RouteCubitScope<FolderBookmarksCubit>(
              create: () => FolderBookmarksCubit(
                folder: folder,
                meta: getIt<BookmarkMetaSource>(),
                ayahs: getIt<AyahLookup>(),
                batch: getIt<AyahBatchLookup>(),
              ),
              identity: folder,
              start: (cubit) => cubit.start(),
              child: FolderBookmarksScreen(folder: folder),
            );
          },
        ),
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
