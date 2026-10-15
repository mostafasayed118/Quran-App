import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;

void main() {
  late AppDatabase db;
  late CityRepository repo;
  late FakePrayerTimeService fake;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    fake = FakePrayerTimeService()
      ..todayResult = [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
        PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
        PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
        PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ]
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = PrayerTimesCubit(prayer: fake, city: repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<PrayerTimesCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const PrayerTimesScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('no city selected shows the prompt and picker button',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('لم تُحدَّد مدينة بعد'), findsOneWidget);
    expect(find.text('اختر مدينتك'), findsOneWidget);
  });

  testWidgets('selected city renders six labeled times with next highlighted',
      (tester) async {
    await repo.select(cairoCity);
    await pumpHost(tester);

    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('شروق'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
    expect(find.text('٠٤:٤٥'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });
}
