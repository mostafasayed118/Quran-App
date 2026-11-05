import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/ramadan_calendar.dart';
import 'package:quran_yahdi/features/ramadan/presentation/ramadan_cubit.dart';
import 'package:quran_yahdi/features/ramadan/presentation/ramadan_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

class _City implements CitySource {
  @override
  Future<City?> selectedCity() async => _cairo;

  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) => [
        PrayerChoice(
            PrayerName.fajr, DateTime(day.year, day.month, day.day, 5)),
        PrayerChoice(
          PrayerName.sunrise,
          DateTime(day.year, day.month, day.day, 6, 20),
        ),
        PrayerChoice(
          PrayerName.dhuhr,
          DateTime(day.year, day.month, day.day, 12),
        ),
        PrayerChoice(
            PrayerName.asr, DateTime(day.year, day.month, day.day, 15)),
        PrayerChoice(
          PrayerName.maghrib,
          DateTime(day.year, day.month, day.day, 18),
        ),
        PrayerChoice(
          PrayerName.isha,
          DateTime(day.year, day.month, day.day, 19, 30),
        ),
      ];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      today(c, whenLocal).first;
}

class _Calendar implements RamadanCalendar {
  @override
  ({int year, int month, int day}) hijriDate(DateTime date) =>
      (year: 1448, month: 9, day: 3);

  @override
  DateTime gregorianDate(int year, int month, int day) =>
      DateTime(2027, 2, 18 + day - 1);

  @override
  int daysInMonth(int year, int month) => 30;

  @override
  String monthName(int year, int month) => 'رمضان';
}

Future<RamadanCubit> _readyCubit() async {
  final cubit = RamadanCubit(
    city: _City(),
    prayer: _Prayer(),
    calendar: _Calendar(),
    clock: () => DateTime(2027, 2, 20),
  );
  await cubit.start();
  return cubit;
}

Widget _app(RamadanCubit cubit, {double textScale = 1}) => BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const RamadanScreen(),
      ),
    );

void main() {
  testWidgets('renders the month header, today and the table', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = await _readyCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('رمضان'), findsOneWidget);
    expect(find.text('رمضان ١٤٤٨'), findsOneWidget);
    expect(find.text('اليوم ٣ رمضان'), findsOneWidget);
    expect(find.text('الإمساك'), findsWidgets);
    expect(find.text('الإفطار'), findsWidgets);
    expect(find.text('١'), findsWidgets);
  });

  testWidgets('survives textScale 2.0 at 360 wide', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = await _readyCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit, textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
