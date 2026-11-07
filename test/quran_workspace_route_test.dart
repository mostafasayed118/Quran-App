import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/data/juz_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_repository.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_source.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_source.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_pane.dart';
import 'package:quran_yahdi/features/quran/presentation/workspace/quran_workspace_screen.dart';
import 'package:quran_yahdi/features/tracker/data/khatma_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

late Directory _tmp;
late AppDatabase _testDb;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 60,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Disposes the app inside the test body so drift's zero-delay stream-close
/// timer is flushed before the framework's pending-timer check.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _tmp = Directory.systemTemp.createTempSync('quran_workspace_route');
    PathProviderPlatform.instance = _TempSupportPathProvider(_tmp.path);
  });

  tearDownAll(() async {
    await getIt.reset();
    resetDependenciesForTest();
    if (_tmp.existsSync()) _tmp.deleteSync(recursive: true);
  });

  setUp(() async {
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: () async => const <Map<String, dynamic>>[],
    );
    // Keep the route test fast and deterministic: every source the Quran tab
    // and the reader touch points at a seeded in-memory database.
    _testDb = newTestDb();
    await _testDb.batch((b) => b.insertAll(_testDb.surahs, [
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 1,
              pagesStart: 1,
              pagesEnd: 1),
        ]));
    await _testDb.batch((b) => b.insertAll(_testDb.ayahs, [
          AyahsCompanion.insert(
              id: const Value(8),
              surahId: 1,
              numberInSurah: 1,
              juz: 1,
              page: 1,
              textUthmani: 'بسم الله الرحمن الرحيم',
              textImlaei: 'بسم الله الرحمن الرحيم'),
        ]));

    getIt.unregister<SurahSource>();
    getIt.registerSingleton<SurahSource>(SurahRepository(_testDb));
    getIt.unregister<AyahRepository>();
    getIt.registerSingleton<AyahRepository>(AyahRepository(_testDb));
    getIt.unregister<AyahLookup>();
    getIt.registerSingleton<AyahLookup>(getIt<AyahRepository>());
    getIt.unregister<JuzIndexSource>();
    getIt.registerSingleton<JuzIndexSource>(JuzRepository(_testDb));
    getIt.unregister<PageAnchorSource>();
    getIt.registerSingleton<PageAnchorSource>(PageAnchorRepository(_testDb));
    getIt.unregister<LastReadRepository>();
    getIt.registerSingleton<LastReadRepository>(LastReadRepository(_testDb));
    getIt.unregister<KhatmaRepository>();
    getIt.registerSingleton<KhatmaRepository>(KhatmaRepository(_testDb));
    getIt.unregister<ReaderSettingsRepository>();
    getIt.registerSingleton<ReaderSettingsRepository>(
      ReaderSettingsRepository(_testDb),
    );
  });

  tearDown(() async {
    await _testDb.close();
    await getIt.reset();
    resetDependenciesForTest();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: AppRouter.router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    ));
  }

  Future<void> openWorkspace(WidgetTester tester) async {
    AppRouter.router.go(AppRoutes.quran);
    await pumpApp(tester);
    await _pumpUntil(
      tester,
      () => find.byType(QuranWorkspaceScreen).evaluate().isNotEmpty,
    );
  }

  Future<void> openFirstSurah(WidgetTester tester) async {
    final row = find.descendant(
      of: find.byKey(const Key('quran-master')),
      matching: find.text('الفاتحة'),
    );
    await _pumpUntil(tester, () => row.evaluate().isNotEmpty);
    await tester.tap(row);
    await _pumpUntil(
      tester,
      () => find.byType(ReaderPane).evaluate().isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('compact keeps the plain surah index', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.quran);
    await pumpApp(tester);
    await _pumpUntil(
      tester,
      () => find.byType(SurahIndexScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(SurahIndexScreen), findsOneWidget);
    expect(find.byType(QuranWorkspaceScreen), findsNothing);

    await disposeApp(tester);
  });

  testWidgets(
      'expanded opens the pane without changing the URL and back clears',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openWorkspace(tester);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);

    await openFirstSurah(tester);

    expect(find.byType(ReaderPane), findsOneWidget);
    expect(AppRouter.router.state.uri.path, AppRoutes.quran);

    // System back clears the pane and keeps the tab.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ReaderPane), findsNothing);
    expect(find.byType(QuranWorkspaceScreen), findsOneWidget);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('resizing to compact with a live reader unmounts cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openWorkspace(tester);
    await openFirstSurah(tester);

    tester.view.physicalSize = const Size(800, 600);
    await _pumpUntil(
      tester,
      () => find.byType(SurahIndexScreen).evaluate().isNotEmpty,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SurahIndexScreen), findsOneWidget);
    expect(find.byType(QuranWorkspaceScreen), findsNothing);

    await disposeApp(tester);
  });
}
