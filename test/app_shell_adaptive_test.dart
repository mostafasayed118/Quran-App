import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/layout/app_breakpoints.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 80,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_shell_wide');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  setUp(() async {
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: () async => const <Map<String, dynamic>>[],
    );
  });

  Future<void> pumpApp(WidgetTester tester, {double? textScale}) async {
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
      builder: textScale == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
    ));
    await _pumpUntil(
      tester,
      () =>
          find.byType(NavigationRail).evaluate().isNotEmpty ||
          find.byType(NavigationBar).evaluate().isNotEmpty,
    );
  }

  testWidgets('an expanded window uses the navigation rail, not the bar',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(4));
    expect(rail.selectedIndex, 0);
  });

  testWidgets('a medium window keeps the bottom bar', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tapping a rail destination switches tab and selection',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.access_time_outlined));
    await _pumpUntil(
      tester,
      () => find.byType(PrayerTimesScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(PrayerTimesScreen), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 2);
  });

  test('the expanded breakpoint is the M3 expanded class', () {
    expect(AppBreakpoints.expanded, 840);
    expect(AppBreakpoints.medium, 600);
  });

  testWidgets('the rail survives textScale 2.0 at 1024 wide', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester, textScale: 2.0);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
