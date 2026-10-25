import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/ayah_lookup.dart';
import '../core/domain/city.dart';
import '../core/domain/last_read.dart';
import '../core/domain/prayer_times.dart';
import '../core/domain/quran_limits.dart';
import '../core/domain/reminders.dart';
import '../core/utils/app_routes.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/azkar/data/azkar_repository.dart';
import '../features/azkar/presentation/azkar_cubit.dart';
import '../features/azkar/presentation/azkar_screen.dart';
import '../features/asma/data/asma_repository.dart';
import '../features/asma/presentation/asma_cubit.dart';
import '../features/asma/presentation/asma_screen.dart';
import '../features/backup/data/backup_service.dart';
import '../features/backup/presentation/backup_cubit.dart';
import '../features/backup/presentation/backup_section.dart';
import '../features/duas/data/dua_repository.dart';
import '../features/duas/data/ruqyah_repository.dart';
import '../features/duas/presentation/duas_cubit.dart';
import '../features/duas/presentation/duas_screen.dart';
import '../features/tasbih/data/tasbih_repository.dart';
import '../features/tasbih/presentation/tasbih_cubit.dart';
import '../features/tasbih/presentation/tasbih_screen.dart';
import '../features/tracker/data/khatma_repository.dart';
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
import '../features/quran/data/quran_search_source.dart';
import '../features/quran/data/surah_source.dart';
import '../features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_screen.dart';
import '../features/quran/presentation/index/surah_index_cubit.dart';
import '../features/quran/presentation/index/surah_index_screen.dart';
import '../features/quran/presentation/reader/reader_cubit.dart';
import '../features/quran/presentation/reader/reader_screen.dart';
import '../features/quran/presentation/search/quran_search_cubit.dart';
import '../features/quran/presentation/search/quran_search_screen.dart';
import '../features/settings/presentation/settings_cubit.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/prayer/data/city_repository.dart';
import '../features/prayer/data/location_service.dart';
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
import '../features/qibla/data/heading_service.dart';
import '../features/qibla/data/qibla_service.dart';
import '../features/qibla/presentation/qibla_cubit.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../l10n/app_localizations.dart';
import 'di/injector.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    errorBuilder: (context, state) {
      final loc = AppLocalizations.of(context);
      return PlaceholderScreen(
        title: loc.pageNotFound,
        hint: loc.pageNotFoundHint,
        actionLabel: loc.home,
        onAction: () => context.go(AppRoutes.home),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(
            lastRead: getIt<LastReadMarker>(),
            ayahs: getIt<AyahLookup>(),
            prayer: getIt<PrayerTimesPort>(),
            city: getIt<CitySource>(),
          ),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.quran,
        builder: (_, __) => BlocProvider<SurahIndexCubit>(
          create: (_) => SurahIndexCubit(getIt<SurahSource>()),
          child: const SurahIndexScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.quranSearch,
        builder: (_, __) => BlocProvider<QuranSearchCubit>(
          create: (_) => QuranSearchCubit(getIt<QuranSearchSource>()),
          child: const QuranSearchScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recitation,
        builder: (_, __) => BlocProvider<RecitersCubit>(
          create: (_) => RecitersCubit(repo: getIt<ReciterRepository>()),
          child: const RecitersScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (_, __) => BlocProvider<LibraryCubit>(
          create: (_) => getIt<LibraryCubit>(),
          child: const LibraryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hadith,
        builder: (context, state) {
          final pack = state.uri.queryParameters[AppRouteQuery.pack] ?? '';
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
        path: AppRoutes.prayerTimes,
        builder: (_, __) => BlocProvider<PrayerTimesCubit>(
          create: (_) => PrayerTimesCubit(
            prayer: getIt<PrayerTimesPort>(),
            city: getIt<CitySource>(),
            settings: getIt<ReminderSettingsPort>(),
            scheduler: getIt<ReminderSchedulerPort>(),
          ),
          child: const PrayerTimesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.cityPicker,
        builder: (_, __) => BlocProvider<CityPickerCubit>(
          create: (_) => CityPickerCubit(
            cityRepo: getIt<CityRepository>(),
            location: getIt<LocationService>(),
          ),
          child: const CityPickerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qibla,
        builder: (_, __) => BlocProvider<QiblaCubit>(
          create: (_) => QiblaCubit(
            city: getIt<CitySource>(),
            qibla: getIt<QiblaService>(),
            heading: getIt<HeadingService>(),
          ),
          child: const QiblaScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.azkar,
        builder: (_, __) => BlocProvider<AzkarCubit>(
          create: (_) => AzkarCubit(
            repository: getIt<AzkarRepository>(),
          ),
          child: const AzkarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.tasbih,
        builder: (_, __) => BlocProvider<TasbihCubit>(
          create: (_) => TasbihCubit(repo: getIt<TasbihRepository>()),
          child: const TasbihScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.duas,
        builder: (_, __) => BlocProvider<DuasCubit>(
          create: (_) => DuasCubit(
            duas: getIt<DuaRepository>(),
            ruqyah: getIt<RuqyahRepository>(),
            ayahs: getIt<AyahLookup>(),
          ),
          child: const DuasScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.worship,
        builder: (_, __) => BlocProvider<TrackerCubit>(
          create: (_) => TrackerCubit(
            repo: getIt<PrayerLogRepository>(),
            khatma: getIt<KhatmaRepository>(),
          ),
          child: const TrackerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.zakat,
        builder: (_, __) => BlocProvider<ZakatCubit>(
          create: (_) => ZakatCubit(),
          child: const ZakatScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hijri,
        builder: (_, __) => BlocProvider<HijriCubit>(
          create: (_) => HijriCubit(service: getIt<HijriService>()),
          child: const HijriScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.asma,
        builder: (_, __) => BlocProvider<AsmaCubit>(
          create: (_) => AsmaCubit(repository: getIt<AsmaRepository>()),
          child: const AsmaScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit(
                settings: getIt<ReminderSettingsPort>(),
                city: getIt<CitySource>(),
                prayer: getIt<PrayerTimesPort>(),
                scheduler: getIt<ReminderSchedulerPort>(),
              ),
            ),
            BlocProvider<BackupCubit>(
              create: (_) => BackupCubit(service: getIt<BackupService>()),
            ),
          ],
          child: const SettingsScreen(backupSection: BackupSection()),
        ),
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (context, state) {
          final surah = (int.tryParse(
                      state.uri.queryParameters[AppRouteQuery.surah] ?? '') ??
                  kFirstSurahId)
              .clamp(kFirstSurahId, kSurahCount);
          final ayahParam = int.tryParse(
                  state.uri.queryParameters[AppRouteQuery.ayah] ?? '') ??
              0;
          final ayah = ayahParam < 0 ? 0 : ayahParam;
          return MultiBlocProvider(
            providers: [
              BlocProvider<ReaderCubit>(
                key: ValueKey('reader:$surah:$ayah'),
                create: (_) => ReaderCubit(
                  ayahRepository: getIt<AyahRepository>(),
                  lastReadRepository: getIt<LastReadRepository>(),
                  surahId: surah,
                  initialAyah: ayah,
                  wirdProgress: getIt<KhatmaRepository>(),
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
        path: AppRoutes.bookmarks,
        builder: (_, __) => BlocProvider<BookmarksCubit>(
          create: (_) => BookmarksCubit(
            getIt<AyahRepository>(),
            pager: getIt<AyahRepository>(),
          ),
          child: const BookmarksScreen(),
        ),
      ),
    ],
  );
}
