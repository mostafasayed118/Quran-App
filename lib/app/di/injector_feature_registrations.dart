part of 'injector.dart';

void _registerQuran(AppDatabase db) {
  getIt.registerLazySingleton<SurahRepository>(() => SurahRepository(db));
  getIt.registerLazySingleton<SurahSource>(() => getIt<SurahRepository>());
  getIt.registerLazySingleton<AyahRepository>(
      () => AyahRepository(db, meta: getIt<BookmarkMetaRepository>()));
  getIt.registerLazySingleton<AyahLookup>(() => getIt<AyahRepository>());
  getIt.registerLazySingleton<AyahBatchLookup>(() => getIt<AyahRepository>());
  getIt.registerLazySingleton<HomeWidgetUpdater>(
      () => const PlatformHomeWidgetUpdater());
  getIt.registerLazySingleton<BookmarkMetaRepository>(
      () => BookmarkMetaRepository(db));
  getIt.registerLazySingleton<BookmarkMetaSource>(
      () => getIt<BookmarkMetaRepository>());
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
  getIt.registerLazySingleton<ReaderLayoutSource>(
      () => getIt<ReaderSettingsRepository>());
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
  getIt
      .registerLazySingleton<LastReadMarker>(() => getIt<LastReadRepository>());
}

void _registerRecitation(
  AppDatabase db,
  Future<Directory> Function()? audioRootResolver,
) {
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
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
        adhanStates: getIt<AdhanPlayer>().state,
        surahNames: getIt<ReciterRepository>(),
      ));
}

void _registerPrayerAndNotifications(
  AppDatabase db,
  Future<List<Map<String, dynamic>>> Function()? citiesLoader,
) {
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
      () => NotificationsBinding(store: getIt<ReminderPlanStore>()));
  getIt.registerLazySingleton<ReminderPlanStore>(
      () => DriftReminderPlanStore(getIt<AppDatabase>()));
  getIt.registerLazySingleton<PreAdhanCanceller>(
      () => getIt<NotificationsBinding>());
  getIt.registerLazySingleton<ReminderSchedulerPort>(
      () => getIt<NotificationsBinding>());
  // The reliability card reads the last plan write's outcome through this
  // port; the binding owns it.
  getIt.registerLazySingleton<ReminderApplyHealth>(
      () => getIt<NotificationsBinding>());
  // Reminder-health readout for the settings screen: a thin platform channel
  // with no state of its own, so each call re-reads the OS (a permission
  // revoked while the app was backgrounded must show up on resume).
  getIt.registerLazySingleton<ReminderDiagnostics>(
      () => const ReminderDiagnosticsChannel());
  getIt.registerLazySingleton<CityRepository>(
      () => CityRepository(db: db, loader: citiesLoader ?? _emptyCitiesLoader));
  getIt.registerLazySingleton<CitySource>(() => getIt<CityRepository>());
  // The chrome's period source. It reads the same ports the prayer screen
  // does, and listens to the concrete repository's change signal (the port
  // deliberately has none: eighteen test fakes implement it).
  getIt.registerLazySingleton<PrayerPeriodController>(
      () => PrayerPeriodController(
            city: getIt<CitySource>(),
            times: getIt<PrayerTimesPort>(),
            config: getIt<PrayerConfigSource>(),
            cityChanges: getIt<CityRepository>().changes,
          ));
}

void _registerWorship(
  AppDatabase db,
  Future<Map<String, dynamic>> Function()? azkarLoader,
  Future<List<Map<String, dynamic>>> Function()? duasLoader,
  Future<List<Map<String, dynamic>>> Function()? ruqyahLoader,
  Future<List<Map<String, dynamic>>> Function()? asmaLoader,
) {
  getIt.registerLazySingleton<TasbihRepository>(() => TasbihRepository(db));
  getIt.registerLazySingleton<PrayerLogRepository>(
      () => PrayerLogRepository(db));
  getIt.registerLazySingleton<KhatmaRepository>(() => KhatmaRepository(db));
  getIt.registerLazySingleton<HijriService>(() => HijriService());
  getIt.registerLazySingleton<HijriOffsetRepository>(
      () => HijriOffsetRepository(db));
  getIt.registerLazySingleton<HijriOffsetSource>(
      () => getIt<HijriOffsetRepository>());
  getIt.registerLazySingleton<RamadanCalendar>(() => getIt<HijriService>());
  getIt.registerLazySingleton<QadaRepository>(() => QadaRepository(db));
  getIt.registerLazySingleton<QadaSource>(() => getIt<QadaRepository>());
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
}

void _registerLibraryAndHadith(
  AppDatabase db,
  Future<List<Map<String, dynamic>>> Function()? libraryCatalogLoader,
  Future<Directory> Function()? libraryRootResolver,
) {
  getIt.registerLazySingleton<CatalogSource>(() =>
      BundledCatalogSource(loader: libraryCatalogLoader ?? _emptyRowsLoader));
  getIt.registerLazySingleton<CatalogRepository>(
      () => CatalogRepository(source: getIt<CatalogSource>()));
  if (libraryCatalogLoader != null && libraryRootResolver != null) {
    getIt.registerLazySingleton<PackDownloader>(() => PackDownloader(
          db,
          libraryRootResolver: libraryRootResolver,
        ));
    getIt.registerLazySingleton<TranslationSearchSource>(
        () => PackTranslationSearchSource(getIt<PackDownloader>()));
  }
  getIt.registerLazySingleton<HadithBookmarkRepository>(
      () => HadithBookmarkRepository(db));
  getIt.registerLazySingleton<HadithBookmarkSource>(
      () => getIt<HadithBookmarkRepository>());
  getIt.registerLazySingleton<HadithPositionRepository>(
      () => HadithPositionRepository(db));
  getIt.registerLazySingleton<HadithPositionSource>(
      () => getIt<HadithPositionRepository>());
}

void _registerBackup(AppDatabase db) {
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
}
