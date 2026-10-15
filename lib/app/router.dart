import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../core/widgets/placeholder_screen.dart';
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
      GoRoute(path: '/library', builder: (_, __) => const PlaceholderScreen(title: 'المكتبة')),
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
          create: (_) => CityPickerCubit(cityRepo: getIt<CityRepository>()),
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
      GoRoute(path: '/azkar', builder: (_, __) => const PlaceholderScreen(title: 'الأذكار')),
      GoRoute(path: '/tasbih', builder: (_, __) => const PlaceholderScreen(title: 'السبحة')),
      GoRoute(path: '/duas', builder: (_, __) => const PlaceholderScreen(title: 'الأدعية والرقية')),
      GoRoute(path: '/worship', builder: (_, __) => const PlaceholderScreen(title: 'تتبع العبادات')),
      GoRoute(path: '/zakat', builder: (_, __) => const PlaceholderScreen(title: 'الزكاة')),
      GoRoute(path: '/hijri', builder: (_, __) => const PlaceholderScreen(title: 'التقويم الهجري')),
      GoRoute(path: '/asma', builder: (_, __) => const PlaceholderScreen(title: 'أسماء الله الحسنى')),
      GoRoute(path: '/settings', builder: (_, __) => const PlaceholderScreen(title: 'الإعدادات')),
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
