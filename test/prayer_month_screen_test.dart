import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_month/prayer_month_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_month/prayer_month_screen.dart';

import 'support/host.dart';

class _City implements CitySource {
  const _City();

  @override
  Future<City?> selectedCity() async => const City(
        id: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        lat: 30.0444,
        lng: 31.2357,
      );

  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => [
        PrayerChoice(PrayerName.fajr,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 5)),
        PrayerChoice(PrayerName.dhuhr,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 12)),
        PrayerChoice(PrayerName.asr,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 15)),
        PrayerChoice(PrayerName.maghrib,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 17, 30)),
        PrayerChoice(PrayerName.isha,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 19)),
      ];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, whenLocal.add(const Duration(hours: 1)));
}

void main() {
  testWidgets('renders the month and pages to the next one', (tester) async {
    final cubit = PrayerMonthCubit(
      city: const _City(),
      prayer: _Prayer(),
      clock: () => DateTime(2026, 11, 15),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: BlocProvider<PrayerMonthCubit>.value(
        value: cubit,
        child: const PrayerMonthScreen(),
      ),
    );

    expect(find.text('جدول الشهر'), findsOneWidget);
    expect(find.textContaining('نوفمبر'), findsWidgets);
    expect(find.textContaining('فجر'), findsWidgets);

    await tester.tap(find.byTooltip('الشهر التالي'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.textContaining('ديسمبر'), findsWidgets);
  });

  testWidgets('320 dp at textScale 2.0 survives the timetable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = PrayerMonthCubit(
      city: const _City(),
      prayer: _Prayer(),
      clock: () => DateTime(2026, 11, 15),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      textScale: 2.0,
      home: BlocProvider<PrayerMonthCubit>.value(
        value: cubit,
        child: const PrayerMonthScreen(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('جدول الشهر'), findsOneWidget);
    expect(find.textContaining('فجر'), findsWidgets);
  });
}
