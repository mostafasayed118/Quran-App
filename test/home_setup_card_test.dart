import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService;
import 'support/test_db.dart';

class _Status implements OnboardingStatusSource {
  _Status(this.completed);

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

HomeCubit _cubit({required bool onboarded}) => HomeCubit(
      lastRead: LastReadRepository(newTestDb()),
      ayahs: AyahRepository(newTestDb()),
      prayer: FakePrayerTimeService(),
      city: CityRepository(
        db: newTestDb(),
        loader: () async => const <Map<String, dynamic>>[],
      ),
      onboarding: _Status(onboarded),
    );

Widget _host({required Widget home}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const Scaffold(body: Text('onboarding-route')),
      ),
    ],
  );
  return MaterialApp.router(
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
}

void main() {
  testWidgets('a fresh install advertises the setup flow', (tester) async {
    final cubit = _cubit(onboarded: false);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<HomeCubit>.value(
        value: cubit,
        child: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('أكمل الإعداد'), findsOneWidget);
    expect(find.text('اختر مدينتك وفعّل التنبيهات.'), findsOneWidget);
  });

  testWidgets('an onboarded user never sees the setup card', (tester) async {
    final cubit = _cubit(onboarded: true);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<HomeCubit>.value(
        value: cubit,
        child: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('أكمل الإعداد'), findsNothing);
  });

  testWidgets('the card opens the onboarding route', (tester) async {
    final cubit = _cubit(onboarded: false);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<HomeCubit>.value(
        value: cubit,
        child: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أكمل الإعداد'));
    await tester.pumpAndSettle();

    expect(find.text('onboarding-route'), findsOneWidget);
  });
}
