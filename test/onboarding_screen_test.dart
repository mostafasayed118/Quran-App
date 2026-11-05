import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/onboarding/presentation/onboarding_cubit.dart';
import 'package:quran_yahdi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _City implements CitySource {
  _City(this.city);

  City? city;

  @override
  Future<City?> selectedCity() async => city;

  @override
  Future<void> select(City value) async {
    city = value;
  }
}

class _Status implements OnboardingStatusSource {
  _Status();

  bool completed = false;
  int writes = 0;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    writes++;
    completed = true;
  }
}

class _Scheduler implements ReminderSchedulerPort {
  int requests = 0;

  @override
  Future<bool> ensurePermissions() async {
    requests++;
    return true;
  }

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {}
}

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

/// A tiny router so the screen can push the city picker and pop on finish.
Widget _host({required Widget home}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: AppRoutes.onboardingCity,
        builder: (_, __) => const Scaffold(body: Text('city-picker')),
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
  testWidgets('the flow shows both steps and the start button', (tester) async {
    final cubit = OnboardingCubit(
      city: _City(null),
      status: _Status(),
      reminders: _Scheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('البداية'), findsOneWidget);
    expect(find.text('اختر مدينتك'), findsOneWidget);
    expect(find.text('تفعيل تذكير الصلوات'), findsOneWidget);
    expect(find.text('ابدأ الاستخدام'), findsOneWidget);
  });

  testWidgets('the city step opens the flow-scoped picker route',
      (tester) async {
    final cubit = OnboardingCubit(
      city: _City(null),
      status: _Status(),
      reminders: _Scheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختر مدينتك'));
    await tester.pumpAndSettle();

    // A sub-route of the flow, not the standalone picker: while the flag is
    // unset the gate redirects every other route, which used to collapse the
    // picker to a single page and break its pop.
    expect(find.text('city-picker'), findsOneWidget);
  });

  testWidgets('start stores the flag', (tester) async {
    final status = _Status();
    final cubit = OnboardingCubit(
      city: _City(null),
      status: status,
      reminders: _Scheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ابدأ الاستخدام'));
    await tester.pumpAndSettle();

    expect(status.writes, 1);
    expect(status.completed, isTrue);
  });

  testWidgets('skip stores the flag too', (tester) async {
    final status = _Status();
    final cubit = OnboardingCubit(
      city: _City(null),
      status: status,
      reminders: _Scheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخطّي'));
    await tester.pumpAndSettle();

    expect(status.writes, 1);
  });

  testWidgets('a selected city shows its name and a change action',
      (tester) async {
    final cubit = OnboardingCubit(
      city: _City(_cairo),
      status: _Status(),
      reminders: _Scheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('المدينة: القاهرة'), findsOneWidget);
    expect(find.text('تغيير المدينة'), findsOneWidget);
  });

  testWidgets('the reminder action asks through the scheduler seam',
      (tester) async {
    final scheduler = _Scheduler();
    final cubit = OnboardingCubit(
      city: _City(null),
      status: _Status(),
      reminders: scheduler,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_host(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();

    expect(scheduler.requests, 1);
    expect(find.text('التنبيهات مفعّلة'), findsOneWidget);
  });
}
