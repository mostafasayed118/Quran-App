import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:quran_yahdi/app/onboarding_gate.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/media_playback_control.dart';
import 'package:quran_yahdi/features/notifications/data/just_audio_adhan_player.dart';
import 'package:quran_yahdi/features/recitation/playback/background_init_guard.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/core/domain/app_theme.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/core/theme/app_theme_controller.dart';
import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/notifications/data/adhan_preferences_impl.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_diagnostics_channel.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/onboarding/data/onboarding_repository.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/configured_prayer_times.dart';
import 'package:quran_yahdi/features/prayer/data/location_service.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_config_repository.dart';
import 'package:quran_yahdi/features/qibla/data/compass_calibration.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/data/juz_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_repository.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_source.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_source.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_repository.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_source.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/just_audio_playback_service.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/settings/data/app_locale_repository.dart';
import 'package:quran_yahdi/features/settings/data/app_theme_repository.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tracker/data/khatma_repository.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';

/// The app layer is the composition root: it is the only place allowed to
/// know every feature at once (core never imports a feature).
final getIt = GetIt.instance;

bool _configured = false;

/// Fallback city catalog: the city repository is always registered, so a
/// boot without the cities asset degrades to "no city picked" instead of a
/// null-registration crash on the first route that resolves it.
Future<List<Map<String, dynamic>>> _emptyCitiesLoader() async =>
    const <Map<String, dynamic>>[];

/// Fallback content catalogs: the azkar/duas/ruqyah/asma/library repositories
/// are always registered, so a boot (or a test) without their bundled assets
/// degrades to the feature's empty state instead of a missing-registration
/// crash on the first route that resolves them.
Future<List<Map<String, dynamic>>> _emptyRowsLoader() async =>
    const <Map<String, dynamic>>[];

/// The azkar catalog is an object (`{'collections': [...]}`), not a list.
Future<Map<String, dynamic>> _emptyAzkarLoader() async =>
    const <String, dynamic>{'collections': <Map<String, dynamic>>[]};

/// Registers every feature's dependencies in the app's service locator.
///
/// This is the composition root: it is the ONLY layer allowed to know all
/// the features at once (core never imports a feature, and a feature never
/// imports the app layer).
///
/// Registration rules:
/// - a repository, a service or a port is a LAZY SINGLETON — one instance
///   for the whole app lifetime;
/// - a route-scoped cubit is never registered here: the router's
///   `RouteCubitScope` creates one instance per entry and closes it on exit,
///   because a shared instance would leak state between two visits to the route.
///
/// The optional loader arguments are the seam for boot (assets) and for the
/// tests; a loader left out means that feature registers its empty fallback,
/// so the screen degrades to its empty state instead of crashing on a missing
/// registration. [PackDownloader] is the exception: it needs a writable root,
/// so it registers only when both the catalog and the root resolver are
/// passed, and its routes redirect home while it is absent.
///
/// Calling it twice is a no-op: the second call returns immediately.
Future<void> configureDependencies({
  Future<Directory> Function()? audioRootResolver,
  Future<List<Map<String, dynamic>>> Function()? citiesLoader,
  Future<Map<String, dynamic>> Function()? azkarLoader,
  Future<List<Map<String, dynamic>>> Function()? duasLoader,
  Future<List<Map<String, dynamic>>> Function()? ruqyahLoader,
  Future<List<Map<String, dynamic>>> Function()? asmaLoader,
  Future<List<Map<String, dynamic>>> Function()? libraryCatalogLoader,
  Future<Directory> Function()? libraryRootResolver,
}) async {
  if (_configured) return;
  getIt.registerLazySingleton<AppDatabase>(
      () => AppDatabase(LazyDatabase(openAppDatabase)));
  final db = getIt<AppDatabase>();
  getIt.registerLazySingleton<SurahRepository>(() => SurahRepository(db));
  getIt.registerLazySingleton<SurahSource>(() => getIt<SurahRepository>());
  getIt.registerLazySingleton<AyahRepository>(() => AyahRepository(db));
  getIt.registerLazySingleton<AyahLookup>(() => getIt<AyahRepository>());
  // Unicode Uthmani reading assets (OFL). Separate from the DB on purpose:
  // no migration, and a missing asset only disables selection for that surah.
  getIt.registerLazySingleton<UthmaniTextSource>(
    () => AssetUthmaniTextSource(rootBundle),
  );
  getIt.registerLazySingleton<QuranSearchSource>(
      () => QuranSearchRepository(db));
  getIt.registerLazySingleton<JuzIndexSource>(() => JuzRepository(db));
  getIt.registerLazySingleton<PageAnchorSource>(() => PageAnchorRepository(db));
  getIt.registerLazySingleton<ReaderSettingsRepository>(
      () => ReaderSettingsRepository(db));
  getIt.registerLazySingleton<ReaderSettingsSource>(
      () => getIt<ReaderSettingsRepository>());
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
  getIt
      .registerLazySingleton<LastReadMarker>(() => getIt<LastReadRepository>());
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
  getIt.registerLazySingleton<PrayerConfigRepository>(
      () => PrayerConfigRepository(db));
  getIt.registerLazySingleton<PrayerConfigSource>(
      () => getIt<PrayerConfigRepository>());
  getIt.registerLazySingleton<PrayerTimesPort>(
      () => ConfiguredPrayerTimes(getIt<PrayerConfigSource>()));
  getIt.registerLazySingleton<QiblaService>(() => const QiblaService());
  getIt.registerLazySingleton<HeadingService>(() => HeadingService());
  getIt.registerLazySingleton<CompassCalibration>(() => CompassCalibration());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<AdhanPreferences>(() => AdhanPreferencesImpl(db));
  getIt.registerLazySingleton<ReminderSettings>(() => ReminderSettings(
        db,
        prayerConfig: getIt<PrayerConfigSource>(),
        preAdhanCanceller: getIt<NotificationsBinding>(),
        adhanPrefs: getIt<AdhanPreferences>(),
      ));
  getIt.registerLazySingleton<ReminderSettingsPort>(
      () => getIt<ReminderSettings>());
  getIt.registerLazySingleton<PrayerReminderSettingsPort>(
      () => getIt<ReminderSettings>());
  getIt.registerLazySingleton<ReminderRescheduler>(
      () => getIt<ReminderSettings>());
  getIt.registerLazySingleton<NotificationsBinding>(
      () => NotificationsBinding());
  getIt.registerLazySingleton<PreAdhanCanceller>(
      () => getIt<NotificationsBinding>());
  getIt.registerLazySingleton<ReminderSchedulerPort>(
      () => getIt<NotificationsBinding>());
  // Reminder-health readout for the settings screen: a thin platform channel
  // with no state of its own, so each call re-reads the OS (a permission
  // revoked while the app was backgrounded must show up on resume).
  getIt.registerLazySingleton<ReminderDiagnostics>(
      () => const ReminderDiagnosticsChannel());
  getIt.registerLazySingleton<TasbihRepository>(() => TasbihRepository(db));
  getIt.registerLazySingleton<PrayerLogRepository>(
      () => PrayerLogRepository(db));
  getIt.registerLazySingleton<KhatmaRepository>(() => KhatmaRepository(db));
  getIt.registerLazySingleton<HijriService>(() => HijriService());
  // Restore reschedules reminders through the same guarded path as boot
  // (`runBootReminderSchedule` composition; no feature import lands on backup).
  // The prayer configuration is re-read first: an import may have replaced the
  // calculation method, madhab, per-prayer set or pre-adhan lead, and the
  // configured prayer port reads the repository's cached `current`.
  getIt.registerLazySingleton<BackupService>(() => BackupService(
        db: db,
        reschedule: () async {
          await getIt<PrayerConfigRepository>().load();
          await getIt<ReminderRescheduler>().reschedule(
            city: getIt<CitySource>(),
            prayer: getIt<PrayerTimesPort>(),
            scheduler: getIt<ReminderSchedulerPort>(),
          );
        },
      ));
  getIt.registerLazySingleton<CityRepository>(
      () => CityRepository(db: db, loader: citiesLoader ?? _emptyCitiesLoader));
  getIt.registerLazySingleton<CitySource>(() => getIt<CityRepository>());
  getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepository(db));
  // One instance serves both the router gate and the flow: the gate caches the
  // flag for the synchronous redirect, and a finish/skip notifies the router.
  getIt.registerLazySingleton<OnboardingGate>(
      () => AppRouter.onboardingGate..attach(getIt<OnboardingRepository>()));
  getIt.registerLazySingleton<OnboardingStatusSource>(
      () => getIt<OnboardingGate>());
  getIt.registerLazySingleton<AppLocaleRepository>(
      () => AppLocaleRepository(db));
  getIt.registerLazySingleton<AppLocaleSource>(
      () => getIt<AppLocaleRepository>());
  // One controller feeds the app root (MaterialApp.locale) and the settings
  // row; the app entry point calls load() behind the first frame.
  getIt.registerLazySingleton<AppLocaleController>(
      () => AppLocaleController(getIt<AppLocaleSource>()));
  getIt.registerLazySingleton<AppThemeRepository>(() => AppThemeRepository(db));
  getIt
      .registerLazySingleton<AppThemeSource>(() => getIt<AppThemeRepository>());
  // Same shape for the appearance: the root rebuilds `MaterialApp.themeMode`
  // and the settings row shows the current choice.
  getIt.registerLazySingleton<AppThemeController>(
      () => AppThemeController(getIt<AppThemeSource>()));
  getIt.registerLazySingleton<AzkarRepository>(
      () => AzkarRepository(loader: azkarLoader ?? _emptyAzkarLoader));
  getIt.registerLazySingleton<AzkarSavedStateRepository>(
      () => AzkarSavedStateRepository(db));
  getIt.registerLazySingleton<AzkarSavedStateSource>(
      () => getIt<AzkarSavedStateRepository>());
  getIt.registerLazySingleton<DuaRepository>(
      () => DuaRepository(loader: duasLoader ?? _emptyRowsLoader));
  getIt.registerLazySingleton<RuqyahRepository>(
      () => RuqyahRepository(loader: ruqyahLoader ?? _emptyRowsLoader));
  getIt.registerLazySingleton<AsmaRepository>(
      () => AsmaRepository(loader: asmaLoader ?? _emptyRowsLoader));
  getIt.registerLazySingleton<CatalogSource>(() =>
      BundledCatalogSource(loader: libraryCatalogLoader ?? _emptyRowsLoader));
  getIt.registerLazySingleton<CatalogRepository>(
      () => CatalogRepository(source: getIt<CatalogSource>()));
  if (libraryCatalogLoader != null && libraryRootResolver != null) {
    getIt.registerLazySingleton<PackDownloader>(() => PackDownloader(
          db,
          libraryRootResolver: libraryRootResolver,
        ));
  }
  getIt.registerLazySingleton<JustAudioPlaybackService>(
      () => JustAudioPlaybackService());
  getIt.registerLazySingleton<PlaybackService>(
      () => getIt<JustAudioPlaybackService>());
  // The adhan player's "stop the Quran first" seam. A separate registration
  // rather than a cast, so swapping the playback implementation cannot fail at
  // runtime.
  getIt.registerLazySingleton<MediaPlaybackControl>(
      () => getIt<JustAudioPlaybackService>());
  getIt.registerLazySingleton<AdhanPlayer>(
    () => JustAudioAdhanPlayer(
      // Resolves when the boot-time audio init settles (or its fail-open
      // timeout fires), so an early play request waits instead of dropping.
      ready: () => BackgroundInitGuard.ready,
      control: getIt<MediaPlaybackControl>(),
    ),
    dispose: (player) {
      // Narrow to the implementation: the port deliberately exposes no
      // lifecycle method, and this is the only owner of the singleton.
      if (player is JustAudioAdhanPlayer) unawaited(player.dispose());
    },
  );
  // Registered unconditionally: the reader and reciter routes read these
  // cubits directly. A degraded boot without a writable audio root must still
  // reach the reader; only starting a download then fails (AudioDownloader
  // throws DownloadFailure from its missing root).
  getIt.registerLazySingleton<AudioDownloader>(
      () => AudioDownloader(db, audioRootResolver: audioRootResolver));
  // App-scoped: the download queue must survive leaving the route.
  getIt.registerLazySingleton<DownloadsCubit>(() => DownloadsCubit(
      downloader: getIt<AudioDownloader>(),
      reciters: getIt<ReciterRepository>()));
  // App-scoped: the player (and its mini player) must survive navigation.
  getIt.registerLazySingleton<PlaybackCubit>(() => PlaybackCubit(
        service: getIt<PlaybackService>(),
        reciters: getIt<ReciterRepository>(),
        downloader: getIt<AudioDownloader>(),
      ));
  _configured = true;
}
