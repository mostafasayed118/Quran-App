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
import 'package:quran_yahdi/core/widgets/empty_state.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_screen.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_screen.dart';
import 'package:quran_yahdi/features/library/presentation/library_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// The Arabic `noResults` copy every empty state renders.
const String _noResults = 'لا نتائج مطابقة';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

/// Bounded frame pumping (never `pumpAndSettle` — drift loads in the
/// background).
Future<void> _pumpRounds(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until [done] holds or [maxRounds] is reached.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 60,
}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_degrade');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  setUp(() async {
    // Deliberately NO azkar/duas/ruqyah/asma/library-catalog loaders and no
    // library root: this is the degraded boot the empty fallbacks exist for.
    // `_configured` makes a second configure a no-op, so this file configures
    // once (in setUp) and never reconfigures.
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: () async => const <Map<String, dynamic>>[],
    );
  });

  testWidgets(
      'a boot without the optional loaders degrades to empty states and '
      'sends the library home', (tester) async {
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
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // /azkar — AzkarRepository is registered with an empty catalog and the
    // screen shows its localized empty state.
    AppRouter.router.go(AppRoutes.azkar);
    await _pumpUntil(
      tester,
      () => find.byType(AzkarScreen).evaluate().isNotEmpty,
    );
    await _pumpRounds(tester);
    expect(find.byType(AzkarScreen), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(_noResults), findsOneWidget);
    expect(tester.takeException(), isNull);

    // /duas — both DuaRepository and RuqyahRepository resolve; the dua tab is
    // the empty state (no tab switch needed).
    AppRouter.router.go(AppRoutes.duas);
    await _pumpUntil(
      tester,
      () => find.byType(DuasScreen).evaluate().isNotEmpty,
    );
    await _pumpRounds(tester);
    expect(find.byType(DuasScreen), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(_noResults), findsOneWidget);
    expect(tester.takeException(), isNull);

    // /asma — AsmaRepository resolves with an empty list.
    AppRouter.router.go(AppRoutes.asma);
    await _pumpUntil(
      tester,
      () => find.byType(AsmaScreen).evaluate().isNotEmpty,
    );
    await _pumpRounds(tester);
    expect(find.byType(AsmaScreen), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(_noResults), findsOneWidget);
    expect(tester.takeException(), isNull);

    // /library — no PackDownloader was registered (no writable root), so the
    // route redirects home instead of resolving it.
    expect(getIt.isRegistered<PackDownloader>(), isFalse);
    AppRouter.router.go(AppRoutes.library);
    await _pumpUntil(
      tester,
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
    );
    await _pumpRounds(tester);
    expect(find.byType(LibraryScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // /library/hadith — the same guard.
    AppRouter.router.go(AppRoutes.hadith);
    await _pumpUntil(
      tester,
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
    );
    await _pumpRounds(tester);
    expect(find.byType(HadithScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
