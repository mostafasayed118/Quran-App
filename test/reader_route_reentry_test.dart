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

/// Bounded double-pumping (never `pumpAndSettle` — drift loads in the
/// background): each round pumps a frame and gives the real event loop a turn
/// for the file-backed database work.
Future<void> _settleBounded(
  WidgetTester tester, {
  int rounds = 20,
  Duration frame = const Duration(milliseconds: 150),
}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(frame);
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
    await _settleBounded(tester);

    AppRouter.router.go('/quran/reader?surah=1');
    await _settleBounded(tester);
    expect(_appBarText('الفاتحة'), findsOneWidget,
        reason: 'cold entry must show the target surah (الفاتحة)');

    // Same route path, query-only change — the warm-link defect's scope.
    AppRouter.router.go('/quran/reader?surah=2');
    await _settleBounded(tester);
    expect(_appBarText('البقرة'), findsOneWidget,
        reason: 'a same-route deep link must re-enter the reader at البقرة');
    expect(_appBarText('الفاتحة'), findsNothing,
        reason: 'the previously open surah must not stay on screen');

    // Same-URI idempotency: repeating the identical link keeps البقرة.
    AppRouter.router.go('/quran/reader?surah=2');
    await _settleBounded(tester);
    expect(_appBarText('البقرة'), findsOneWidget);

    // Cross-path sanity: leaving the route and returning stays healthy.
    AppRouter.router.go('/quran');
    await _settleBounded(tester);
    expect(find.byType(SurahIndexScreen), findsOneWidget);

    AppRouter.router.go('/quran/reader?surah=2');
    await _settleBounded(tester);
    expect(_appBarText('البقرة'), findsOneWidget,
        reason: 'cross-path re-entry must keep working');

    // Release the file-backed database so the temp-dir teardown can delete it.
    await tester.runAsync(() => getIt<AppDatabase>().close());
  });
}
