import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/azkar/data/azkar_repository.dart';
import '../features/azkar/presentation/azkar_cubit.dart';
import '../features/azkar/presentation/azkar_screen.dart';
import '../features/asma/data/asma_repository.dart';
import '../features/asma/presentation/asma_cubit.dart';
import '../features/asma/presentation/asma_screen.dart';
import '../features/duas/data/dua_repository.dart';
import '../features/duas/data/ruqyah_repository.dart';
import '../features/duas/presentation/duas_cubit.dart';
import '../features/duas/presentation/duas_screen.dart';
import '../features/tasbih/data/tasbih_repository.dart';
import '../features/tasbih/presentation/tasbih_cubit.dart';
import '../features/tasbih/presentation/tasbih_screen.dart';
import '../features/tracker/data/prayer_log_repository.dart';
import '../features/tracker/presentation/tracker_cubit.dart';
import '../features/tracker/presentation/tracker_screen.dart';
import '../features/zakat/presentation/zakat_cubit.dart';
import '../features/zakat/presentation/zakat_screen.dart';
import '../features/hijri/data/hijri_service.dart';
import '../features/library/presentation/hadith_browse/hadith_cubit.dart';
import '../features/library/presentation/hadith_browse/hadith_screen.dart';
import '../features/library/data/pack_downloader.dart';
import '../features/library/presentation/library_cubit.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/hijri/presentation/hijri_cubit.dart';
import '../features/hijri/presentation/hijri_screen.dart';
import '../features/home/presentation/home_cubit.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/quran/data/ayah_repository.dart';
import '../features/quran/data/last_read_repository.dart';
import '../features/quran/data/surah_repository.dart';
import '../features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_screen.dart';
import '../features/quran/presentation/index/surah_index_cubit.dart';
import '../features/quran/presentation/index/surah_index_screen.dart';
import '../features/quran/presentation/reader/reader_cubit.dart';
import '../features/quran/presentation/reader/reader_screen.dart';
import '../features/prayer/data/city_repository.dart';
import '../features/prayer/data/location_service.dart';
import '../features/prayer/data/prayer_time_service.dart';
import '../features/prayer/presentation/city_picker/city_picker_cubit.dart';
import '../features/prayer/presentation/city_picker/city_picker_screen.dart';
import '../features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import '../features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import '../features/recitation/data/reciter_repository.dart';
import '../features/recitation/presentation/downloads/downloads_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import '../features/recitation/presentation/reciters/reciters_cubit.dart';
import '../features/recitation/presentation/reciters/reciters_screen.dart';
import '../features/recitation/presentation/playback/playback_cubit.dart';
import '../features/qibla/data/qibla_service.dart';
import '../features/qibla/presentation/qibla_cubit.dart';
import '../features/qibla/presentation/qibla_screen.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(
            lastRead: getIt<LastReadRepository>(),
            ayahs: getIt<AyahRepository>(),
            prayer: getIt<PrayerTimeService>(),
            city: getIt<CityRepository>(),
          ),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/quran',
        builder: (_, __) => BlocProvider<SurahIndexCubit>(
          create: (_) => SurahIndexCubit(getIt<SurahRepository>()),
          child: const SurahIndexScreen(),
        ),
      ),
      GoRoute(
        path: '/recitation',
        builder: (_, __) => BlocProvider<RecitersCubit>(
          create: (_) =>
              RecitersCubit(repo: getIt<ReciterRepository>()),
          child: const RecitersScreen(),
        ),
      ),
      GoRoute(
        path: '/library',
        builder: (_, __) => BlocProvider<LibraryCubit>.value(
          value: getIt<LibraryCubit>(),
          child: const LibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/library/hadith',
        builder: (context, state) {
          final pack = state.uri.queryParameters['pack'] ?? '';
          return BlocProvider<HadithCubit>(
            create: (_) => HadithCubit(
              downloader: getIt<PackDownloader>(),
              packId: pack,
            ),
            child: const HadithScreen(),
          );
        },
      ),
      GoRoute(
        path: '/prayer-times',
        builder: (_, __) => BlocProvider<PrayerTimesCubit>(
          create: (_) => PrayerTimesCubit(
            prayer: getIt<PrayerTimeService>(),
            city: getIt<CityRepository>(),
          ),
          child: const PrayerTimesScreen(),
        ),
      ),
      GoRoute(
        path: '/prayer-times/city',
        builder: (_, __) => BlocProvider<CityPickerCubit>(
          create: (_) => CityPickerCubit(
            cityRepo: getIt<CityRepository>(),
            location: getIt<LocationService>(),
          ),
          child: const CityPickerScreen(),
        ),
      ),
      GoRoute(
        path: '/qibla',
        builder: (_, __) => BlocProvider<QiblaCubit>(
          create: (_) => QiblaCubit(
            city: getIt<CityRepository>(),
            qibla: getIt<QiblaService>(),
          ),
          child: const QiblaScreen(),
        ),
      ),
      GoRoute(
        path: '/azkar',
        builder: (_, __) => BlocProvider<AzkarCubit>(
          create: (_) => AzkarCubit(
            repository: getIt<AzkarRepository>(),
          ),
          child: const AzkarScreen(),
        ),
      ),
      GoRoute(
        path: '/tasbih',
        builder: (_, __) => BlocProvider<TasbihCubit>(
          create: (_) => TasbihCubit(repo: getIt<TasbihRepository>()),
          child: const TasbihScreen(),
        ),
      ),
      GoRoute(
        path: '/duas',
        builder: (_, __) => BlocProvider<DuasCubit>(
          create: (_) => DuasCubit(
            duas: getIt<DuaRepository>(),
            ruqyah: getIt<RuqyahRepository>(),
            ayahs: getIt<AyahRepository>(),
          ),
          child: const DuasScreen(),
        ),
      ),
      GoRoute(
        path: '/worship',
        builder: (_, __) => BlocProvider<TrackerCubit>(
          create: (_) => TrackerCubit(repo: getIt<PrayerLogRepository>()),
          child: const TrackerScreen(),
        ),
      ),
      GoRoute(
        path: '/zakat',
        builder: (_, __) => BlocProvider<ZakatCubit>(
          create: (_) => ZakatCubit(),
          child: const ZakatScreen(),
        ),
      ),
      GoRoute(
        path: '/hijri',
        builder: (_, __) => BlocProvider<HijriCubit>(
          create: (_) => HijriCubit(service: getIt<HijriService>()),
          child: const HijriScreen(),
        ),
      ),
      GoRoute(
        path: '/asma',
        builder: (_, __) => BlocProvider<AsmaCubit>(
          create: (_) => AsmaCubit(repository: getIt<AsmaRepository>()),
          child: const AsmaScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, _) => PlaceholderScreen(
          title: AppLocalizations.of(context).settings,
        ),
      ),
      GoRoute(
        path: '/quran/reader',
        builder: (context, state) {
          final surah =
              int.tryParse(state.uri.queryParameters['surah'] ?? '') ?? 1;
          final ayah =
              int.tryParse(state.uri.queryParameters['ayah'] ?? '') ?? 0;
          return MultiBlocProvider(
            providers: [
              BlocProvider<ReaderCubit>(
                create: (_) => ReaderCubit(
                  ayahRepository: getIt<AyahRepository>(),
                  lastReadRepository: getIt<LastReadRepository>(),
                  surahId: surah,
                  initialAyah: ayah,
                ),
              ),
              BlocProvider<PlaybackCubit>.value(
                value: getIt<PlaybackCubit>(),
              ),
            ],
            child: const ReaderScreen(),
          );
        },
      ),
      GoRoute(
        path: '/recitation/reciter',
        builder: (context, state) {
          final row = state.uri.queryParameters['row'] ?? '';
          return MultiBlocProvider(
            providers: [
              BlocProvider<PlaybackCubit>.value(
                value: getIt<PlaybackCubit>(),
              ),
              BlocProvider<DownloadsCubit>.value(
                value: getIt<DownloadsCubit>(),
              ),
              BlocProvider<ReciterSurahsCubit>(
                create: (_) => ReciterSurahsCubit(
                  reciters: getIt<ReciterRepository>(),
                  downloads: getIt<DownloadsCubit>(),
                  rowId: row,
                ),
              ),
            ],
            child: const ReciterSurahsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (_, __) => BlocProvider<BookmarksCubit>(
          create: (_) => BookmarksCubit(getIt<AyahRepository>()),
          child: const BookmarksScreen(),
        ),
      ),
    ],
  );
}
