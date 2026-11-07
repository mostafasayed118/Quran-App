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
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/workspace/quran_workspace_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

late Directory _tmp;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 40,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
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
  });

  tearDown(() async {
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

  testWidgets('expanded mounts the workspace on the same /quran route',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.quran);
    await pumpApp(tester);
    await _pumpUntil(
      tester,
      () => find.byType(QuranWorkspaceScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(QuranWorkspaceScreen), findsOneWidget);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);
    expect(AppRouter.router.state.uri.path, AppRoutes.quran);

    await disposeApp(tester);
  });

  testWidgets('resizing expanded to compact unmounts the workspace',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppRouter.router.go(AppRoutes.quran);
    await pumpApp(tester);
    await _pumpUntil(
      tester,
      () => find.byType(QuranWorkspaceScreen).evaluate().isNotEmpty,
    );

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
