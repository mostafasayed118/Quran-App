import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
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
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_shell');
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
    await _pumpUntil(
      tester,
      () => find.byType(NavigationBar).evaluate().isNotEmpty,
    );
  }

  testWidgets('the four primary destinations live in a persistent bar',
      (tester) async {
    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(4));
    expect(bar.selectedIndex, 0);
    expect(find.byType(HomeScreen), findsOneWidget);
    // The mini player is mounted by the shell (zero-height while idle) so a
    // playing track stays controllable on every tab.
    expect(find.byType(MiniPlayerBar), findsOneWidget);

    // Prayer times is the third destination; its outlined icon is unique on
    // Home (the tile there uses the schedule glyph).
    await tester.tap(find.byIcon(Icons.access_time_outlined));
    await _pumpUntil(
      tester,
      () => find.byType(PrayerTimesScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(PrayerTimesScreen), findsOneWidget);
    final afterTap = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(afterTap.selectedIndex, 2);
  });

  testWidgets('a detail route opens full screen, above the bar',
      (tester) async {
    AppRouter.router.go(AppRoutes.home);
    await pumpApp(tester);

    AppRouter.router.go(AppRoutes.qibla);
    await _pumpUntil(
      tester,
      () => find.byType(QiblaScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(QiblaScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
