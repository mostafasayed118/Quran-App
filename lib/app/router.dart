import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/quran/data/ayah_repository.dart';
import '../features/quran/data/last_read_repository.dart';
import '../features/quran/data/surah_repository.dart';
import '../features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_screen.dart';
import '../features/quran/presentation/index/surah_index_cubit.dart';
import '../features/quran/presentation/index/surah_index_screen.dart';
import '../features/quran/presentation/reader/reader_cubit.dart';
import '../features/quran/presentation/reader/reader_screen.dart';
import '../features/recitation/data/reciter_repository.dart';
import '../features/recitation/presentation/downloads/downloads_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import '../features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import '../features/recitation/presentation/reciters/reciters_cubit.dart';
import '../features/recitation/presentation/reciters/reciters_screen.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const PlaceholderScreen(title: 'الرئيسية')),
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
      GoRoute(path: '/prayer-times', builder: (_, __) => const PlaceholderScreen(title: 'مواقيت الصلاة')),
      GoRoute(path: '/qibla', builder: (_, __) => const PlaceholderScreen(title: 'القبلة')),
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
          return BlocProvider<ReaderCubit>(
            create: (_) => ReaderCubit(
              ayahRepository: getIt<AyahRepository>(),
              lastReadRepository: getIt<LastReadRepository>(),
              surahId: surah,
              initialAyah: ayah,
            ),
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
