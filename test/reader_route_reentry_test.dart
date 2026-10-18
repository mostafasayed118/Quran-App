import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  final String path;

  _TempSupportPathProvider(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

/// The reader's AppBar carries the surah name; scoping to the AppBar keeps the
/// assertion off the basmala/ayah cards of the (lazily built) verse list.
Finder _appBarText(String text) => find.descendant(
      of: find.byType(AppBar),
      matching: find.text(text),
    );

bool _showsInAppBar(String text) => _appBarText(text).evaluate().isNotEmpty;

/// Bounded frame pumping (never `pumpAndSettle` — drift loads in the
/// background): each round pumps a frame and gives the real event loop a turn
/// for the file-backed database work.
Future<void> _pumpRounds(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

/// Pumps until [done] holds or [maxRounds] is reached — a bounded,
/// load-tolerant wait (the suite runs test files in parallel).
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 80,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_reader_re');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  setUp(() async {
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: defaultCitiesLoader,
    );
  });

  testWidgets(
      'a same-route query-only deep link re-enters the reader at its target',
      (tester) async {
    // Warm the file-backed database (asset copy + open) once, off the frame
    // clock, so the navigations below are not gated by first-open I/O.
    await tester.runAsync(
        () => getIt<AppDatabase>().customSelect('SELECT 1').getSingle());

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
    await _pumpRounds(tester);

    try {
      AppRouter.router.go('/quran/reader?surah=1');
      await _pumpUntil(tester, () => _showsInAppBar('الفاتحة'));
      expect(_appBarText('الفاتحة'), findsOneWidget,
          reason: 'cold entry must show the target surah (الفاتحة)');

      // Same route path, query-only change — the warm-link defect's scope.
      AppRouter.router.go('/quran/reader?surah=2');
      await _pumpUntil(tester, () => _showsInAppBar('البقرة'));
      expect(_appBarText('البقرة'), findsOneWidget,
          reason: 'a same-route deep link must re-enter the reader at البقرة');
      expect(_appBarText('الفاتحة'), findsNothing,
          reason: 'the previously open surah must not stay on screen');

      // Same-URI idempotency: repeating the identical link keeps البقرة.
      AppRouter.router.go('/quran/reader?surah=2');
      await _pumpRounds(tester);
      expect(_appBarText('البقرة'), findsOneWidget);

      // Cross-path sanity: leaving the route and returning stays healthy.
      AppRouter.router.go('/quran');
      await _pumpUntil(
        tester,
        () => find.byType(SurahIndexScreen).evaluate().isNotEmpty,
        maxRounds: 30,
      );
      expect(find.byType(SurahIndexScreen), findsOneWidget);

      AppRouter.router.go('/quran/reader?surah=2');
      await _pumpUntil(tester, () => _showsInAppBar('البقرة'));
      expect(_appBarText('البقرة'), findsOneWidget,
          reason: 'cross-path re-entry must keep working');
    } finally {
      // Let the last navigation's stream cancellations settle on the frame
      // clock before releasing the file-backed database — closing against a
      // pending frame-clock timer deadlocks in the real-async zone. The
      // timeout turns any residual stall into a loud test failure.
      await _pumpRounds(tester, rounds: 16);
      await tester.runAsync(() =>
          getIt<AppDatabase>().close().timeout(const Duration(seconds: 20)));
    }
  });
}
