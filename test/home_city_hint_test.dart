import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    lastRead = LastReadRepository(db);
    ayahs = AyahRepository(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'first run without a city shows the pick-city hint, opens the picker, '
      'and reloads into the next-prayer card on return', (tester) async {
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => BlocProvider<HomeCubit>.value(
            value: cubit,
            child: const HomeScreen(),
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

    expect(find.text('الصلاة القادمة'), findsNothing);
    expect(find.text('اختر مدينتك'), findsOneWidget);
    expect(find.text('لم تُحدَّد مدينة بعد'), findsOneWidget);

    await tester.tap(find.text('اختر مدينتك'));
    await tester.pumpAndSettle();
    expect(find.text('PICK-CITY-STUB'), findsOneWidget);

    await tester.tap(find.text('PICK-CITY-STUB'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('PICK-CITY-STUB'), findsNothing);
    expect(find.text('اختر مدينتك'), findsNothing);
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('٠٤:٤٥'), findsOneWidget);
  });
}
