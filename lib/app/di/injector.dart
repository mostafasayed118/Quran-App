import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:get_it/get_it.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduler.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/location_service.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_source.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/just_audio_playback_service.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
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

/// Registers every feature's dependencies in the app's service locator.
///
/// This is the composition root: it is the ONLY layer allowed to know all
/// the features at once (core never imports a feature, and a feature never
/// imports the app layer).
///
/// Registration rules:
/// - a repository, a service or a port is a LAZY SINGLETON — one instance
///   for the whole app lifetime;
/// - a route-scoped cubit (one the router creates per entry) is a FACTORY —
///   a shared instance would leak state between two visits to the route.
///
/// The optional loader arguments are the seam for boot (assets) and for the
/// tests; a loader left out means that feature registers nothing, so the
/// screen degrades to its empty state instead of crashing on a missing
/// registration.
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
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
  getIt
      .registerLazySingleton<LastReadMarker>(() => getIt<LastReadRepository>());
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
  getIt.registerLazySingleton<PrayerTimeService>(
      () => const PrayerTimeService());
  getIt
      .registerLazySingleton<PrayerTimesPort>(() => getIt<PrayerTimeService>());
  getIt.registerLazySingleton<QiblaService>(() => const QiblaService());
  getIt.registerLazySingleton<HeadingService>(() => HeadingService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ReminderSettings>(() => ReminderSettings(db));
  getIt.registerLazySingleton<ReminderSettingsPort>(
      () => getIt<ReminderSettings>());
  getIt.registerLazySingleton<NotificationsBinding>(
      () => NotificationsBinding());
  getIt.registerLazySingleton<ReminderScheduler>(
      () => getIt<NotificationsBinding>());
  getIt.registerLazySingleton<ReminderSchedulerPort>(
      () => getIt<ReminderScheduler>());
  getIt.registerLazySingleton<TasbihRepository>(() => TasbihRepository(db));
  getIt.registerLazySingleton<PrayerLogRepository>(
      () => PrayerLogRepository(db));
  getIt.registerLazySingleton<KhatmaRepository>(() => KhatmaRepository(db));
  getIt.registerLazySingleton<HijriService>(() => HijriService());
  // Restore reschedules reminders through the same guarded path as boot
  // (`runBootReminderSchedule` composition; no feature import lands on backup).
  getIt.registerLazySingleton<BackupService>(() => BackupService(
        db: db,
        reschedule: () => scheduleReminders(
          city: getIt<CitySource>(),
          prayer: getIt<PrayerTimesPort>(),
          settings: getIt<ReminderSettingsPort>(),
          scheduler: getIt<ReminderSchedulerPort>(),
        ),
      ));
  getIt.registerLazySingleton<CityRepository>(
      () => CityRepository(db: db, loader: citiesLoader ?? _emptyCitiesLoader));
  getIt.registerLazySingleton<CitySource>(() => getIt<CityRepository>());
  if (azkarLoader != null) {
    getIt.registerLazySingleton<AzkarRepository>(
        () => AzkarRepository(loader: azkarLoader));
  }
  if (duasLoader != null && ruqyahLoader != null) {
    getIt.registerLazySingleton<DuaRepository>(
        () => DuaRepository(loader: duasLoader));
    getIt.registerLazySingleton<RuqyahRepository>(
        () => RuqyahRepository(loader: ruqyahLoader));
  }
  if (asmaLoader != null) {
    getIt.registerLazySingleton<AsmaRepository>(
        () => AsmaRepository(loader: asmaLoader));
  }
  if (libraryCatalogLoader != null) {
    getIt.registerLazySingleton<CatalogSource>(
        () => BundledCatalogSource(loader: libraryCatalogLoader));
    getIt.registerLazySingleton<CatalogRepository>(
        () => CatalogRepository(source: getIt<CatalogSource>()));
  }
  if (libraryCatalogLoader != null && libraryRootResolver != null) {
    getIt.registerLazySingleton<PackDownloader>(() => PackDownloader(
          db,
          libraryRootResolver: libraryRootResolver,
        ));
    // Route-scoped: the library screen owns its own cubit, so a fresh one is
    // built per route entry (a shared instance leaks state between visits).
    getIt.registerFactory<LibraryCubit>(() => LibraryCubit(
          catalog: getIt<CatalogRepository>(),
          downloader: getIt<PackDownloader>(),
        ));
  }
  getIt
      .registerLazySingleton<PlaybackService>(() => JustAudioPlaybackService());
  if (audioRootResolver != null) {
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
  }
  _configured = true;
}
