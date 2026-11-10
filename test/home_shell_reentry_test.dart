import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/app/route_observer.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService;
import 'support/fakes.dart';
import 'support/test_db.dart';

/// Counts [HomeCubit.reload] calls at the seam every reload touches first —
/// `reload` always reads the last-read marker before anything else.
class _CountingLastRead implements LastReadMarker {
  _CountingLastRead(this._inner);

  final LastReadMarker _inner;

  int loads = 0;

  @override
  Future<int?> loadAyahId() {
    loads++;
    return _inner.loadAyahId();
  }
}

/// Bounded frame pumping (never `pumpAndSettle` — the drift-backed cubit keeps
/// work on the real event loop): each round pumps a frame and gives the event
/// loop a turn.
Future<void> _pumpRounds(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

/// Home mounted on a real router, with the reader as a root-level route above
/// it — the shape the app ships, where `didPopNext` never reaches Home.
class _Harness {
  _Harness({required this.cubit, required this.loads, required this.router});

  final HomeCubit cubit;
  final _CountingLastRead loads;
  final GoRouter router;

  int get reloads => loads.loads;
}

_Harness _buildHarness() {
  final db = newTestDb();
  final counting = _CountingLastRead(LastReadRepository(db));
  final cubit = HomeCubit(
    lastRead: counting,
    ayahs: AyahRepository(db),
    prayer: FakePrayerTimeService(),
    city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
  );
  addTearDown(cubit.close);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => BlocProvider<HomeCubit>.value(
          value: cubit,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (_, __) => const Scaffold(body: Text('READER-STUB')),
      ),
    ],
  );
  addTearDown(router.dispose);

  return _Harness(cubit: cubit, loads: counting, router: router);
}

/// The production shape: Home and the three tile destinations inside a
/// `ShellRoute`, the reader as a root-level route above it, and the app's
/// route observer on the router (go_router injects it into the shell's
/// Navigator too).
_Harness _buildShellHarness() {
  final db = newTestDb();
  final counting = _CountingLastRead(LastReadRepository(db));
  final cubit = HomeCubit(
    lastRead: counting,
    ayahs: AyahRepository(db),
    prayer: FakePrayerTimeService(),
    city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
  );
  addTearDown(cubit.close);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    observers: [appRouteObserver],
    routes: [
      ShellRoute(
        builder: (_, __, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => BlocProvider<HomeCubit>.value(
              value: cubit,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.quran,
            builder: (_, __) => const Scaffold(body: Text('QURAN-STUB')),
          ),
          GoRoute(
            path: AppRoutes.prayerTimes,
            builder: (_, __) => const Scaffold(body: Text('PRAYER-STUB')),
          ),
          GoRoute(
            path: AppRoutes.azkar,
            builder: (_, __) => const Scaffold(body: Text('AZKAR-STUB')),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (_, __) => const Scaffold(body: Text('READER-STUB')),
      ),
    ],
  );
  addTearDown(router.dispose);

  return _Harness(cubit: cubit, loads: counting, router: router);
}

Widget _app(GoRouter router) => MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
    );

Future<int> _pumpHome(WidgetTester tester, _Harness harness) async {
  await harness.cubit.start();
  final afterStart = harness.reloads;

  await tester.pumpWidget(_app(harness.router));
  await _pumpRounds(tester);
  return afterStart;
}

void main() {
  testWidgets('returning from the reader reloads Home exactly once',
      (tester) async {
    final harness = _buildHarness();
    final afterStart = await _pumpHome(tester, harness);
    expect(harness.reloads, afterStart,
        reason: 'showing Home must not add a load on top of start()');

    unawaited(harness.router.push(AppRoutes.reader));
    await _pumpRounds(tester);
    expect(find.text('READER-STUB'), findsOneWidget);
    expect(harness.reloads, afterStart,
        reason: 'the reader sitting above Home must not reload it');

    harness.router.pop();
    await _pumpRounds(tester);
    expect(find.text('READER-STUB'), findsNothing);
    expect(harness.reloads, afterStart + 1,
        reason: 'the reader writes last-read, so Home must reload on return');
  });

  testWidgets('showing Home alone never adds a second load', (tester) async {
    final harness = _buildHarness();
    final afterStart = await _pumpHome(tester, harness);

    // The first location event after mount is Home itself; reacting to it
    // would double-load what start() already loaded.
    await _pumpRounds(tester, rounds: 12);
    expect(harness.reloads, afterStart);
  });

  testWidgets('staying on Home does not reload again', (tester) async {
    final harness = _buildHarness();
    final afterStart = await _pumpHome(tester, harness);

    unawaited(harness.router.push(AppRoutes.reader));
    await _pumpRounds(tester);
    harness.router.pop();
    await _pumpRounds(tester);
    expect(harness.reloads, afterStart + 1, reason: 'one reload per return');

    // A second round trip reloads a second time — never more.
    unawaited(harness.router.push(AppRoutes.reader));
    await _pumpRounds(tester);
    harness.router.pop();
    await _pumpRounds(tester);
    expect(harness.reloads, afterStart + 2, reason: 'still one per return');

    // Left alone on Home, no further location event may reload it.
    await _pumpRounds(tester, rounds: 16);
    expect(harness.reloads, afterStart + 2);
  });

  testWidgets('inside the shell, the reader round trip still reloads once',
      (tester) async {
    final harness = _buildShellHarness();
    final afterStart = await _pumpHome(tester, harness);
    expect(harness.reloads, afterStart);

    unawaited(harness.router.push(AppRoutes.reader));
    await _pumpRounds(tester);
    expect(find.text('READER-STUB'), findsOneWidget);

    harness.router.pop();
    await _pumpRounds(tester);
    expect(harness.reloads, afterStart + 1,
        reason: 'a reader return crosses navigators, so only the location '
            'listener fires');
  });

  testWidgets('a shell-owned tile round trip reloads twice', (tester) async {
    final harness = _buildShellHarness();
    final afterStart = await _pumpHome(tester, harness);

    unawaited(harness.router.push(AppRoutes.quran));
    await _pumpRounds(tester);
    expect(find.text('QURAN-STUB'), findsOneWidget);
    expect(harness.reloads, afterStart,
        reason: 'the inner page sitting on Home must not reload it');

    harness.router.pop();
    await _pumpRounds(tester);
    expect(find.text('QURAN-STUB'), findsNothing);

    // Measured, accepted duplication: a shell-child push lands in the shell's
    // own navigator, so the route observer delivers `didPopNext` AND the
    // location changes back to /home — two `reload()` calls for one return.
    // User-invisible: `reload()` emits no loading state and the cubit's
    // sequence token lets only the newest load emit.
    expect(harness.reloads, afterStart + 2,
        reason: 'inner push: didPopNext + location event = 2 reloads');
  });
}
