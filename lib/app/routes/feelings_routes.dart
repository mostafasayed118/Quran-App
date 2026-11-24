part of '../router.dart';

/// Q43–Q46: feelings picker, verse list, verse detail and saved verses.
List<RouteBase> _feelingsRoutes() => [
  GoRoute(
    path: AppRoutes.feelings,
    builder: (_, _) => RouteCubitScope<FeelingsCubit>(
      create: () => FeelingsCubit(getIt<FeelingsRepository>()),
      identity: AppRoutes.feelings,
      start: (cubit) => cubit.start(),
      child: const FeelingsScreen(),
    ),
  ),
  GoRoute(
    path: AppRoutes.feelingsVerses,
    builder: (context, state) {
      final key = FeelingKey.fromValue(
        state.uri.queryParameters[AppRouteQuery.feeling],
      );
      if (key == null) {
        return const Scaffold(body: Center(child: Text('Invalid feeling')));
      }
      return RouteCubitScope<FeelingVersesCubit>(
        create: () => FeelingVersesCubit(getIt<FeelingsRepository>(), key),
        identity: '${AppRoutes.feelingsVerses}:${key.value}',
        start: (cubit) => cubit.start(),
        child: const FeelingVersesScreen(),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.feelingsVerse,
    builder: (context, state) {
      final params = state.uri.queryParameters;
      final key = FeelingKey.fromValue(params[AppRouteQuery.feeling]);
      final surah = int.tryParse(params[AppRouteQuery.surah] ?? '');
      final ayah = int.tryParse(params[AppRouteQuery.ayah] ?? '');
      if (key == null || surah == null || ayah == null) {
        return const Scaffold(body: Center(child: Text('Invalid verse')));
      }
      return RouteCubitScope<VerseDetailCubit>(
        create: () => VerseDetailCubit(
          getIt<FeelingsRepository>(),
          key,
          surah,
          ayah,
          playSurah: (s, name) =>
              getIt<PlaybackCubit>().playDefaultForSurah(s, surahName: name),
        ),
        identity: '${AppRoutes.feelingsVerse}:$surah:$ayah:${key.value}',
        start: (cubit) => cubit.start(),
        child: const VerseDetailScreen(),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.feelingsSaved,
    builder: (_, _) => RouteCubitScope<SavedVersesCubit>(
      create: () => SavedVersesCubit(
        getIt<FeelingsRepository>(),
        lookup: getIt<AyahLookup>(),
      ),
      identity: AppRoutes.feelingsSaved,
      start: (cubit) async {},
      child: const SavedVersesScreen(),
    ),
  ),
];
