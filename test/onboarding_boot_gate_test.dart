import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/di/injector.dart';
import 'package:quran_yahdi/app/onboarding_gate.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _Status implements OnboardingStatusSource {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 60,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// End-to-end proof of the first-run gate on the real router: a fresh install
/// lands on the setup flow, and finishing it lands on Home.
///
/// The gate's storage is a fake here on purpose — the redirect contract is what
/// this test pins, and a real drift read would need `runAsync` plumbing that
/// the rest of the suite does not use.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_gate');
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

  tearDown(() {
    AppRouter.onboardingGate.reset();
  });

  testWidgets('a fresh install opens the setup flow, then lands on home',
      (tester) async {
    // Constructing the gate is what the app entry point does; the DI graph then
    // serves that same instance to the flow.
    final gate = getIt<OnboardingGate>();
    expect(identical(getIt<OnboardingStatusSource>(), gate), isTrue);
    gate.attach(_Status());
    final ready = gate.reload();
    await tester.pump();

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: AppRouter.router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
    ));
    await _pumpUntil(
      tester,
      () => find.byType(OnboardingScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.takeException(), isNull);

    await ready;
    await gate.complete();
    await _pumpUntil(
      tester,
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
