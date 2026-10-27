import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/fakes.dart';
import 'support/test_db.dart';

void main() {
  testWidgets(
      'picking a city reloads the qibla bearing instead of leaving the '
      'empty state on screen', (tester) async {
    final db = newTestDb();
    final city = CityRepository(
      db: db,
      loader: () async => [cairoCity.toJson()],
    );
    final cubit = QiblaCubit(city: city, qibla: FakeQiblaService());
    addTearDown(cubit.close);
    await cubit.start();

    final router = GoRouter(
      initialLocation: '/qibla',
      routes: [
        GoRoute(
          path: '/qibla',
          builder: (_, __) => BlocProvider<QiblaCubit>.value(
            value: cubit,
            child: const QiblaScreen(),
          ),
        ),
        GoRoute(
          path: '/prayer-times/city',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await city.select(cairoCity);
                  if (context.mounted) context.pop(true);
                },
                child: const Text('PICK-CITY-STUB'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(
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
    ));
    await tester.pumpAndSettle();

    expect(find.text('لم تُحدَّد مدينة بعد'), findsOneWidget);
    expect(find.text('اختر مدينتك'), findsOneWidget);

    await tester.tap(find.text('اختر مدينتك'));
    await tester.pumpAndSettle();
    expect(find.text('PICK-CITY-STUB'), findsOneWidget);

    await tester.tap(find.text('PICK-CITY-STUB'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('PICK-CITY-STUB'), findsNothing);
    expect(find.text('اختر مدينتك'), findsNothing);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.textContaining('١٣٧'), findsOneWidget);
  });
}
