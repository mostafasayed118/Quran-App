import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:get_it/get_it.dart';

import '../db/app_database.dart';
import '../db/connection.dart';
import '../../features/quran/data/surah_repository.dart';
import '../../features/quran/data/ayah_repository.dart';
import '../../features/quran/data/last_read_repository.dart';
import '../../features/azkar/data/azkar_repository.dart';
import '../../features/azkar/presentation/azkar_cubit.dart';
import '../../features/prayer/data/city_repository.dart';
import '../../features/tasbih/data/tasbih_repository.dart';
import '../../features/tasbih/presentation/tasbih_cubit.dart';
import '../../features/prayer/data/prayer_time_service.dart';
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
}) async {
  if (_configured) return;
  getIt.registerLazySingleton<AppDatabase>(
      () => AppDatabase(LazyDatabase(openAppDatabase)));
  final db = getIt<AppDatabase>();
  getIt.registerLazySingleton<SurahRepository>(() => SurahRepository(db));
  getIt.registerLazySingleton<AyahRepository>(() => AyahRepository(db));
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
  getIt.registerLazySingleton<PrayerTimeService>(() => const PrayerTimeService());
  getIt.registerLazySingleton<QiblaService>(() => const QiblaService());
  getIt.registerLazySingleton<TasbihRepository>(() => TasbihRepository(db));
  getIt.registerLazySingleton<TasbihCubit>(
      () => TasbihCubit(repo: getIt<TasbihRepository>()));
  if (citiesLoader != null) {
    getIt.registerLazySingleton<CityRepository>(
        () => CityRepository(db: db, loader: citiesLoader));
  }
  if (azkarLoader != null) {
    getIt.registerLazySingleton<AzkarRepository>(
        () => AzkarRepository(loader: azkarLoader));
    getIt.registerLazySingleton<AzkarCubit>(
        () => AzkarCubit(repository: getIt<AzkarRepository>()));
  }
  getIt.registerLazySingleton<PlaybackService>(() => JustAudioPlaybackService());
  if (audioRootResolver != null) {
    getIt.registerLazySingleton<AudioDownloader>(
        () => AudioDownloader(db, audioRootResolver: audioRootResolver));
    getIt.registerLazySingleton<DownloadsCubit>(
        () => DownloadsCubit(
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
