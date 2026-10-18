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

class _CountingPrayerService extends FakePrayerTimeService {
  int todayCalls = 0;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) {
    todayCalls += 1;
    return super.today(c, dayLocal);
  }
}

List<PrayerChoice> _day({int fajrHour = 4, int fajrMinute = 45}) => [
      PrayerChoice(
          PrayerName.fajr, DateTime(2026, 3, 15, fajrHour, fajrMinute)),
      PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
      PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
      PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
      PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
      PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
    ];

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await repo.select(cairoCity);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester, PrayerTimesCubit cubit) async {
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

  testWidgets('app-bar refresh reloads the times in place', (tester) async {
    final fake = _CountingPrayerService()
      ..todayResult = _day()
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(
      prayer: fake,
      city: repo,
      clock: () => DateTime(2026, 3, 15, 14, 0),
    );

    await pumpScreen(tester, cubit);
    expect(fake.todayCalls, 1);
    expect(find.text('٠٤:٤٥'), findsOneWidget);

    fake.todayResult = _day(fajrHour: 5, fajrMinute: 0);
    await tester.tap(find.byTooltip('تحديث'));
    await tester.pumpAndSettle();

    expect(fake.todayCalls, 2);
    expect(find.text('٠٥:٠٠'), findsOneWidget);
    expect(find.text('٠٤:٤٥'), findsNothing);
  });

  testWidgets('pull-to-refresh reloads the times in place', (tester) async {
    final fake = _CountingPrayerService()
      ..todayResult = _day()
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(
      prayer: fake,
      city: repo,
      clock: () => DateTime(2026, 3, 15, 14, 0),
    );

    await pumpScreen(tester, cubit);
    expect(fake.todayCalls, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(fake.todayCalls, 2);
  });
}
