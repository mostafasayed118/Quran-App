import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/ayah_sheet_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/ayah_sheet_state.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/library_sheet.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// FakeAsync-safe pack decoder: isolate completions never arrive under the
/// widget-test zone, so these tests use the PackDownloader decoder seam.
Future<dynamic> _syncDecode(String path) async =>
    jsonDecode(File(path).readAsStringSync());

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

class _FakePlaybackService implements PlaybackService {
  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

/// Installs the two REAL fixture excerpts the sheet reads from.
Future<void> seedPacks(AppDatabase db, Directory tempRoot) async {
  final libraryDir = Directory('${tempRoot.path}/library')
    ..createSync(recursive: true);
  File('test/fixtures/tafsir_wrapper_sample.json')
      .copySync('${libraryDir.path}/ar-tafsir-muyassar.json');
  File('test/fixtures/translation_ara_sirajtafseer_excerpt.json')
      .copySync('${libraryDir.path}/ar-sirajtafseer.json');
  await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
        packId: 'ar-tafsir-muyassar',
        kind: 'tafsir',
        language: 'ar',
        title: 'التفسير الميسر',
        sizeMb: 0.2,
        version: 'v1.2.2',
      ));
  await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
        packId: 'ar-sirajtafseer',
        kind: 'translation',
        language: 'ar',
        title: 'السراج المنير',
        sizeMb: 2.0,
        version: '1',
      ));
}

void main() {
  group('AyahSheetCubit', () {
    late AppDatabase db;
    late Directory tempRoot;

    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
      tempRoot = await Directory.systemTemp.createTemp('qy_ayah_sheet_test');
    });

    tearDown(() async {
      await tempRoot.delete(recursive: true);
      await db.close();
    });

    test('resolves installed tafsir and translation for the ayah', () async {
      await seedPacks(db, tempRoot);
      final cubit = AyahSheetCubit(
        downloader: PackDownloader(db,
            libraryRootResolver: () async => tempRoot,
            fileDecoder: _syncDecode),
        surah: 1,
        ayah: 1,
      );
      addTearDown(cubit.close);

      final ready = await cubit.stream.firstWhere((s) => s is AyahSheetReady)
          as AyahSheetReady;

      expect(ready.tafsirEntries, hasLength(1));
      expect(ready.tafsirEntries.single.title, 'التفسير الميسر');
      expect(ready.tafsirEntries.single.text, contains('سميت الفاتحة'));
      expect(ready.translationEntries, hasLength(1));
      expect(ready.translationEntries.single.title, 'السراج المنير');
      expect(ready.translationEntries.single.text, isNotEmpty);
    });

    test('no installed packs resolves empty entry lists', () async {
      final cubit = AyahSheetCubit(
        downloader: PackDownloader(db,
            libraryRootResolver: () async => tempRoot,
            fileDecoder: _syncDecode),
        surah: 1,
        ayah: 1,
      );
      addTearDown(cubit.close);

      final ready = await cubit.stream.firstWhere((s) => s is AyahSheetReady)
          as AyahSheetReady;

      expect(ready.tafsirEntries, isEmpty);
      expect(ready.translationEntries, isEmpty);
    });

    test('hadith-kind rows and missing pack files are treated as absent',
        () async {
      final libraryDir = Directory('${tempRoot.path}/library')
        ..createSync(recursive: true);
      File('test/fixtures/hadith_eng_muslim_excerpt.json')
          .copySync('${libraryDir.path}/en-muslim.json');
      await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
            packId: 'en-muslim',
            kind: 'hadith',
            language: 'en',
            title: 'Sahih Muslim',
            sizeMb: 3.9,
            version: '1',
          ));
      await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
            packId: 'ghost-tafsir',
            kind: 'tafsir',
            language: 'ar',
            title: 'حزمة بلا ملف',
            sizeMb: 1.0,
            version: '1',
          ));
      final cubit = AyahSheetCubit(
        downloader: PackDownloader(db,
            libraryRootResolver: () async => tempRoot,
            fileDecoder: _syncDecode),
        surah: 1,
        ayah: 1,
      );
      addTearDown(cubit.close);

      final ready = await cubit.stream.firstWhere((s) => s is AyahSheetReady)
          as AyahSheetReady;

      expect(ready.tafsirEntries, isEmpty);
      expect(ready.translationEntries, isEmpty);
    });

    test('downloader failure lands in the error state, never hangs', () async {
      final cubit = AyahSheetCubit(
        downloader: _ThrowingDownloader(db),
        surah: 1,
        ayah: 1,
      );
      addTearDown(cubit.close);

      final failure = await cubit.stream.firstWhere((s) => s is AyahSheetError)
          as AyahSheetError;

      expect(failure.message, isNotEmpty);
    });
  });

  group('LibrarySheet', () {
    late AppDatabase db;
    late Directory tempRoot;
    late PackDownloader downloader;

    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
      tempRoot = await Directory.systemTemp.createTemp('qy_ayah_sheet_wtest');
      downloader = PackDownloader(db,
          libraryRootResolver: () async => tempRoot, fileDecoder: _syncDecode);
    });

    tearDown(() async {
      await db.close();
      await tempRoot.delete(recursive: true);
    });

    Future<void> pumpLocales(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: child,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('shows ayah tafsir and translation for installed packs',
        (tester) async {
      await tester.runAsync(() => seedPacks(db, tempRoot));
      await pumpLocales(
        tester,
        Scaffold(
          body: LibrarySheet(
            surahId: 1,
            surahName: 'الفاتحة',
            ayah: 1,
            downloader: downloader,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpAndSettle();
      expect(find.text('تفسير الآية وترجمتها'), findsOneWidget);
      expect(find.textContaining('الفاتحة ﴿١﴾'), findsOneWidget);
      expect(find.text('تفسير'), findsOneWidget);
      expect(find.text('ترجمة'), findsOneWidget);
      expect(find.textContaining('سميت الفاتحة'), findsOneWidget);

      await tester.tap(find.text('ترجمة'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('أَبْتَدِئُ'), findsOneWidget);
    });

    testWidgets('empty state routes to the library', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => LibrarySheet(
                        surahId: 1,
                        surahName: 'الفاتحة',
                        ayah: 1,
                        downloader: downloader,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/library',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('library-dest'))),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        routerConfig: router,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
          find.text('لا يوجد تفسير مثبّت — نزّل من المكتبة'), findsOneWidget);

      await tester.tap(find.text('المكتبة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('library-dest'), findsOneWidget);
    });

    testWidgets('reader ayah card affordance opens the sheet', (tester) async {
      await tester.runAsync(() => seedPacks(db, tempRoot));
      // The production sheet resolves via getIt; register strictly
      // sequentially here (awaited, test-scoped).
      await getIt.reset();
      getIt.registerLazySingleton<PackDownloader>(
        () => PackDownloader(db,
            libraryRootResolver: () async => tempRoot,
            fileDecoder: _syncDecode),
      );
      addTearDown(getIt.reset);
      final dbHarness = db;
      final fatiha = [
        AyahsCompanion.insert(
            id: const Value(1),
            surahId: 1,
            numberInSurah: 1,
            juz: 1,
            page: 1,
            textUthmani: 'بسم الله الرحمن الرحيم',
            textImlaei: 'بسم الله الرحمن الرحيم'),
      ];
      await tester.runAsync(() async =>
          dbHarness.batch((b) => b.insertAll(dbHarness.ayahs, fatiha)));
      final cubit = ReaderCubit(
          ayahRepository: _TeardownSafeAyahRepository(dbHarness),
          lastReadRepository: LastReadRepository(dbHarness),
          surahId: 1,
          initialAyah: 0);
      addTearDown(cubit.close);
      final playbackCubit = PlaybackCubit(
        service: _FakePlaybackService(),
        reciters: ReciterRepository(dbHarness),
        downloader: AudioDownloader(dbHarness,
            audioRootResolver: () async => Directory.systemTemp),
      );
      addTearDown(playbackCubit.close);

      await pumpLocales(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<ReaderCubit>.value(value: cubit),
            BlocProvider<PlaybackCubit>.value(value: playbackCubit),
          ],
          child: const ReaderScreen(),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpAndSettle();
      expect(find.text('تفسير الآية وترجمتها'), findsOneWidget);
      expect(find.textContaining('سميت الفاتحة'), findsOneWidget);
    });
  });
}

class _ThrowingDownloader extends PackDownloader {
  _ThrowingDownloader(super.db);

  @override
  Future<List<InstalledPack>> installedPacks() =>
      Future.error(PackFailure('registry read failed'));
}
