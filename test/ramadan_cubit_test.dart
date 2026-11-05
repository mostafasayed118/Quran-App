import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/ramadan_calendar.dart';
import 'package:quran_yahdi/features/ramadan/presentation/ramadan_cubit.dart';
import 'package:quran_yahdi/features/ramadan/presentation/ramadan_state.dart';

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

class _City implements CitySource {
  _City(this.city);

  final City? city;

  @override
  Future<City?> selectedCity() async => city;

  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) => [
        PrayerChoice(
          PrayerName.fajr,
          DateTime(day.year, day.month, day.day, 5),
        ),
        PrayerChoice(
          PrayerName.sunrise,
          DateTime(day.year, day.month, day.day, 6, 20),
        ),
        PrayerChoice(
          PrayerName.dhuhr,
          DateTime(day.year, day.month, day.day, 12),
        ),
        PrayerChoice(
          PrayerName.asr,
          DateTime(day.year, day.month, day.day, 15),
        ),
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
  _Calendar({
    required this.today,
    required this.ramadanStart,
  });

  final ({int year, int month, int day}) today;
  final DateTime ramadanStart;

  @override
  ({int year, int month, int day}) hijriDate(DateTime date) => today;

  @override
  DateTime gregorianDate(int year, int month, int day) => DateTime(
        ramadanStart.year,
        ramadanStart.month,
        ramadanStart.day + day - 1,
      );

  @override
  int daysInMonth(int year, int month) => 30;

  @override
  String monthName(int year, int month) => 'رمضان';
}

void main() {
  test('builds the month, derives the anchors and marks today', () async {
    final cubit = RamadanCubit(
      city: _City(_cairo),
      prayer: _Prayer(),
      calendar: _Calendar(
        today: (year: 1448, month: 9, day: 3),
        ramadanStart: DateTime(2027, 2, 18),
      ),
      clock: () => DateTime(2027, 2, 20),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as RamadanReady;
    expect(ready.hijriYear, 1448);
    expect(ready.monthName, 'رمضان');
    expect(ready.days, hasLength(30));
    expect(ready.today, isNotNull);
    expect(ready.today!.hijriDay, 3);
    expect(ready.today!.date, DateTime(2027, 2, 20));
    expect(ready.today!.imsak, DateTime(2027, 2, 20, 4, 50));
    expect(ready.today!.iftar, DateTime(2027, 2, 20, 18));
    expect(ready.days.first.date, DateTime(2027, 2, 18));
    expect(ready.days.last.date, DateTime(2027, 3, 19));
  });

  test('after Ramadan it targets the next year and marks no today', () async {
    final cubit = RamadanCubit(
      city: _City(_cairo),
      prayer: _Prayer(),
      calendar: _Calendar(
        today: (year: 1448, month: 10, day: 5),
        ramadanStart: DateTime(2028, 2, 7),
      ),
      clock: () => DateTime(2027, 3, 25),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as RamadanReady;
    expect(ready.hijriYear, 1449);
    expect(ready.today, isNull);
    expect(ready.days.first.date, DateTime(2028, 2, 7));
  });

  test('no city yields a ready state with no rows', () async {
    final cubit = RamadanCubit(
      city: _City(null),
      prayer: _Prayer(),
      calendar: _Calendar(
        today: (year: 1448, month: 9, day: 3),
        ramadanStart: DateTime(2027, 2, 18),
      ),
      clock: () => DateTime(2027, 2, 20),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as RamadanReady;
    expect(ready.days, isEmpty);
    expect(ready.today, isNull);
  });

  test('a prayer failure lands in the failed state', () async {
    final cubit = RamadanCubit(
      city: _City(_cairo),
      prayer: _ThrowingPrayer(),
      calendar: _Calendar(
        today: (year: 1448, month: 9, day: 3),
        ramadanStart: DateTime(2027, 2, 18),
      ),
      clock: () => DateTime(2027, 2, 20),
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state, isA<RamadanFailed>());
  });
}

class _ThrowingPrayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) =>
      throw StateError('prayer failed');

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      throw StateError('prayer failed');
}
