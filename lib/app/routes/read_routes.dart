part of '../router.dart';

/// Reading stack reached from the shell: the update gate, Quran search, the
/// library, the reader and the bookmarks.
List<RouteBase> _updateAndSearchRoutes() => [
      GoRoute(
        path: AppRoutes.update,
        // The blocking surface for an unsupported install, or the dismissible
        // optional-update prompt. The mode is read from the gate at build time;
        // the screen receives plain callbacks and never imports the DI root.
        builder: (_, __) {
          final mandatory =
              AppRouter.versionGate.verdict == VersionVerdict.updateRequired;
          return UpdateGateScreen(
            mandatory: mandatory,
            onOpenStore: () => getIt<StoreListingGateway>().open(),
            // Only the recommended (dismissible) surface gets the ack callback.
            onLater: mandatory
                ? null
                : () => AppRouter.versionGate.acknowledgeRecommended(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quranSearch,
        builder: (context, state) => BlocProvider<QuranSearchCubit>(
          create: (_) => QuranSearchCubit(
            getIt<QuranSearchSource>(),
            debounce: const Duration(milliseconds: 300),
          ),
          child: QuranSearchScreen(
            initialQuery: state.uri.queryParameters[AppRouteQuery.q] ?? '',
          ),
        ),
      ),
    ];

List<RouteBase> _libraryRoutes() => [
      GoRoute(
        path: AppRoutes.library,
        // A degraded boot registers no PackDownloader (it needs a writable
        // root); the hub has nothing to show then, so it goes home instead of
        // throwing on the missing registration.
        redirect: (_, __) =>
            getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
        builder: (_, __) => RouteCubitScope<LibraryCubit>(
          create: () => LibraryCubit(
            catalog: getIt<CatalogRepository>(),
            downloader: getIt<PackDownloader>(),
          ),
          identity: AppRoutes.library,
          start: (cubit) => cubit.start(),
          child: const LibraryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hadith,
        // Same degraded-boot guard as /library (the hadith browser reads
        // packs through the downloader).
        redirect: (_, __) =>
            getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
        builder: (context, state) {
          final pack = state.uri.queryParameters[AppRouteQuery.pack] ?? '';
          return RouteCubitScope<HadithCubit>(
            create: () => HadithCubit(
              downloader: getIt<PackDownloader>(),
              packId: pack,
              bookmarks: getIt<HadithBookmarkSource>(),
              positions: getIt<HadithPositionSource>(),
            ),
            identity: pack,
            start: (cubit) => cubit.start(),
            child: const HadithScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.librarySearch,
        redirect: (_, __) =>
            getIt.isRegistered<PackDownloader>() ? null : AppRoutes.home,
        builder: (_, __) => RouteCubitScope<TranslationSearchCubit>(
          create: () => TranslationSearchCubit(
            source: getIt<TranslationSearchSource>(),
            surahName: (id) async =>
                (await getIt<AyahLookup>().surahRefById(id))?.nameAr,
          ),
          identity: AppRoutes.librarySearch,
          start: (cubit) => cubit.start(),
          child: const TranslationSearchScreen(),
        ),
      ),
    ];

List<RouteBase> _readerRoutes() => [
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
              BlocProvider<PlaybackCubit>.value(
                value: getIt<PlaybackCubit>(),
              ),
            ],
            child: ReaderRouteScope(
              surah: surah,
              ayah: ayah,
              create: () => _createReader(surah, ayah),
              // The skin is chrome-only: the reader (and the sheets it opens,
              // which capture this inherited theme) never sees a palette.
              child: const NeutralReadingTheme(child: ReaderScreen()),
            ),
          );
        },
      ),
    ];

List<RouteBase> _bookmarkRoutes() => [
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<BookmarkMetaCubit>(
              create: (_) =>
                  BookmarkMetaCubit(source: getIt<BookmarkMetaSource>())
                    ..start(),
            ),
          ],
          child: RouteCubitScope<BookmarksCubit>(
            create: () => BookmarksCubit(
              getIt<AyahRepository>(),
              pager: getIt<AyahRepository>(),
            ),
            identity: AppRoutes.bookmarks,
            start: (cubit) => cubit.start(),
            child: const BookmarksScreen(showMeta: true),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookmarksFolder,
        builder: (context, state) {
          final folder = state.uri.queryParameters[AppRouteQuery.name] ?? '';
          return RouteCubitScope<FolderBookmarksCubit>(
            create: () => FolderBookmarksCubit(
              folder: folder,
              meta: getIt<BookmarkMetaSource>(),
              ayahs: getIt<AyahLookup>(),
              batch: getIt<AyahBatchLookup>(),
            ),
            identity: folder,
            start: (cubit) => cubit.start(),
            child: FolderBookmarksScreen(folder: folder),
          );
        },
      ),
    ];
