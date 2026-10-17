import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:get_it/get_it.dart';

import '../db/app_database.dart';
import '../db/connection.dart';
import '../../features/quran/data/surah_repository.dart';
import '../../features/quran/data/ayah_repository.dart';
import '../../features/quran/data/last_read_repository.dart';
import '../../features/azkar/data/azkar_repository.dart';
import '../../features/asma/data/asma_repository.dart';
import '../../features/duas/data/dua_repository.dart';
import '../../features/duas/data/ruqyah_repository.dart';
import '../../features/hijri/data/hijri_service.dart';
import '../../features/library/data/catalog_repository.dart';
import '../../features/library/data/library_catalog.dart';
import '../../features/library/data/pack_downloader.dart';
import '../../features/library/presentation/library_cubit.dart';
import '../../features/notifications/data/notifications_binding.dart';
import '../../features/notifications/data/reminder_scheduler.dart';
import '../../features/notifications/data/reminder_settings.dart';
import '../../features/prayer/data/city_repository.dart';
import '../../features/prayer/data/location_service.dart';
import '../../features/tasbih/data/tasbih_repository.dart';
import '../../features/tracker/data/prayer_log_repository.dart';
import '../../features/prayer/data/prayer_time_service.dart';
import '../../features/qibla/data/heading_service.dart';
import '../../features/qibla/data/qibla_service.dart';
import '../../features/recitation/data/audio_downloader.dart';
import '../../features/recitation/data/reciter_repository.dart';
import '../../features/recitation/playback/just_audio_playback_service.dart';
import '../../features/recitation/playback/playback_service.dart';
import '../../features/recitation/presentation/downloads/downloads_cubit.dart';
import '../../features/recitation/presentation/playback/playback_cubit.dart';

final getIt = GetIt.instance;

bool _configured = false;

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
  getIt.registerLazySingleton<AyahRepository>(() => AyahRepository(db));
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
  getIt.registerLazySingleton<PrayerTimeService>(
      () => const PrayerTimeService());
  getIt.registerLazySingleton<QiblaService>(() => const QiblaService());
  getIt.registerLazySingleton<HeadingService>(() => HeadingService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ReminderSettings>(() => ReminderSettings(db));
  getIt.registerLazySingleton<NotificationsBinding>(
      () => NotificationsBinding());
  getIt.registerLazySingleton<ReminderScheduler>(
      () => getIt<NotificationsBinding>());
  getIt.registerLazySingleton<TasbihRepository>(() => TasbihRepository(db));
  getIt.registerLazySingleton<PrayerLogRepository>(
      () => PrayerLogRepository(db));
  getIt.registerLazySingleton<HijriService>(() => HijriService());
  if (citiesLoader != null) {
    getIt.registerLazySingleton<CityRepository>(
        () => CityRepository(db: db, loader: citiesLoader));
  }
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
    getIt.registerLazySingleton<LibraryCubit>(() => LibraryCubit(
          catalog: getIt<CatalogRepository>(),
          downloader: getIt<PackDownloader>(),
        ));
  }
  getIt
      .registerLazySingleton<PlaybackService>(() => JustAudioPlaybackService());
  if (audioRootResolver != null) {
    getIt.registerLazySingleton<AudioDownloader>(
        () => AudioDownloader(db, audioRootResolver: audioRootResolver));
    getIt.registerLazySingleton<DownloadsCubit>(() => DownloadsCubit(
        downloader: getIt<AudioDownloader>(),
        reciters: getIt<ReciterRepository>()));
    getIt.registerLazySingleton<PlaybackCubit>(() => PlaybackCubit(
          service: getIt<PlaybackService>(),
          reciters: getIt<ReciterRepository>(),
          downloader: getIt<AudioDownloader>(),
        ));
  }
  _configured = true;
}
