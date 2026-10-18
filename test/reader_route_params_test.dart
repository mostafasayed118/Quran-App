import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';
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
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_reader_pa');
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

  testWidgets('out-of-contract reader params clamp to the valid contract',
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
      AppRouter.router.go('/quran/reader?surah=999');
      await _pumpUntil(tester, () => _showsInAppBar('الناس'));
      expect(_appBarText('الناس'), findsOneWidget,
          reason: 'surah 999 must clamp to 114 (الناس)');

      AppRouter.router.go('/quran/reader?surah=1&ayah=-7');
      await _pumpUntil(tester, () => _showsInAppBar('الفاتحة'));
      expect(_appBarText('الفاتحة'), findsOneWidget,
          reason: 'surah 1 must render after the param clamp');

      final context = tester.element(find.byType(ReaderScreen));
      final state = BlocProvider.of<ReaderCubit>(context).state;
      expect(state, isA<ReaderReady>());
      expect((state as ReaderReady).initialAyah, 0,
          reason: 'a negative ayah must behave as 0');
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
