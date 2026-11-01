import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_month/prayer_month_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_month/prayer_month_state.dart';

class _City implements CitySource {
  const _City({this.present = true});

  final bool present;

  @override
  Future<City?> selectedCity() async => present
      ? const City(
          id: 'cairo',
          nameAr: 'القاهرة',
          nameEn: 'Cairo',
          lat: 30.0444,
          lng: 31.2357,
        )
      : null;

  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => [
        PrayerChoice(PrayerName.fajr,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 5)),
        PrayerChoice(PrayerName.sunrise,
            DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 6)),
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
  test('a normal month has one row per day and five prayers each', () async {
    final cubit = PrayerMonthCubit(
      city: const _City(),
      prayer: _Prayer(),
      clock: () => DateTime(2026, 11, 15),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as PrayerMonthReady;
    expect(ready.year, 2026);
    expect(ready.month, 11);
    expect(ready.days, hasLength(30));
    expect(ready.days.first.date, DateTime(2026, 11, 1));
    expect(ready.days.last.date, DateTime(2026, 11, 30));
    expect(ready.days.first.prayers, hasLength(5));
    expect(ready.days.first.prayers.map((p) => p.name),
        isNot(contains(PrayerName.sunrise)));
  });

  test('previous and next month roll the year', () async {
    final cubit = PrayerMonthCubit(
      city: const _City(),
      prayer: _Prayer(),
      clock: () => DateTime(2026, 1, 10),
    );
    addTearDown(cubit.close);

    await cubit.start();
    await cubit.previousMonth();
    expect((cubit.state as PrayerMonthReady).month, 12);
    expect((cubit.state as PrayerMonthReady).year, 2025);

    await cubit.nextMonth();
    expect((cubit.state as PrayerMonthReady).month, 1);
    expect((cubit.state as PrayerMonthReady).year, 2026);
  });

  test('February honours the leap year', () async {
    final cubit = PrayerMonthCubit(
      city: const _City(),
      prayer: _Prayer(),
      clock: () => DateTime(2024, 2, 10),
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect((cubit.state as PrayerMonthReady).days, hasLength(29));
  });

  test('no city is a ready empty month, not a failure', () async {
    final cubit = PrayerMonthCubit(
      city: const _City(present: false),
      prayer: _Prayer(),
      clock: () => DateTime(2026, 11, 15),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as PrayerMonthReady;
    expect(ready.city, isNull);
    expect(ready.days, isEmpty);
  });
}
