part of '../router.dart';

/// Audio: the downloads/reciters screens and a reciter's surah list.
List<RouteBase> _recitationRoutes() => [
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

List<RouteBase> _reciterRoutes() => [
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
