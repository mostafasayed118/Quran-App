import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/principles_screen.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/fakes.dart';
import 'support/host.dart';
import 'support/test_db.dart';

/// The owner-approved copy, verbatim: the page must render it unchanged.
const String _free = 'مجاني بلا إعلانات — ولا نيّة لإدخال إعلانات.';
const String _noAccount =
    'بلا حساب — كل شيء يبقى على جهازك، والنسخ الاحتياطي بيدك أنت.';
const String _attribution =
    'التلاوات منسوبة لأصحابها — أي قائمة مستقبلية تُراجع بشريًا قبل النشر.';
const String _futurePaid =
    'إن أضفنا يومًا ميزة مدفوعة، تبقى كل الميزات الحالية مجانية.';

const List<String> _blocks = <String>[
  _free,
  _noAccount,
  _attribution,
  _futurePaid,
];

/// The in-app shell for a router: locale, delegates and the app theme, so a
/// route renders exactly what the app renders.
Widget _routerApp(GoRouter router) => MaterialApp.router(
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

void main() {
  testWidgets('the /settings/principles route renders the four principles',
      (tester) async {
    // The real router: proves the address is wired, not just the widget.
    AppRouter.router.go(AppRoutes.principles);
    await tester.pumpWidget(_routerApp(AppRouter.router));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(PrinciplesScreen), findsOneWidget);
    for (final copy in _blocks) {
      expect(find.text(copy), findsOneWidget);
    }
  });

  testWidgets('renders at textScaler 2.0 without overflowing', (tester) async {
    await pumpAppHost(
      tester,
      home: const PrinciplesScreen(),
      textScale: 2.0,
    );

    // Scroll the whole page: every block must lay out at the largest device
    // text size, not just the ones on the first screen.
    for (final copy in _blocks) {
      await tester.scrollUntilVisible(find.text(copy), 120);
      expect(find.text(copy), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the English mirror renders the page', (tester) async {
    await pumpAppHost(
      tester,
      home: const PrinciplesScreen(),
      locale: const Locale('en'),
    );

    expect(find.text('Principles'), findsOneWidget);
    expect(
      find.text('Free, with no ads — and no intention of adding any.'),
      findsOneWidget,
    );
  });

  testWidgets('the settings row under the licenses opens the page',
      (tester) async {
    final db = newTestDb();
    final cubit = SettingsCubit(
      settings: ReminderSettings(db),
      city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
      prayer: FakePrayerTimeService(),
      scheduler: FakeReminderScheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    // Two routes only: the row has to push the DECLARED address, and that
    // address has to render the page. The DI-heavy settings host would bring
    // the whole locator in for no extra coverage.
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => BlocProvider<SettingsCubit>.value(
            value: cubit,
            child: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.principles,
          builder: (_, __) => const PrinciplesScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.scrollUntilVisible(find.text('مبادئ التطبيق'), 100);
    await tester.tap(find.text('مبادئ التطبيق'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(PrinciplesScreen), findsOneWidget);
    expect(find.text(_free), findsOneWidget);
  });
}
