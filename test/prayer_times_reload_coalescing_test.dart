import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';

import 'support/fakes.dart';
import 'support/test_db.dart';

const _dubai = City(
  id: 'dubai',
  nameAr: 'دبي',
  nameEn: 'Dubai',
  lat: 25.2048,
  lng: 55.2708,
);

class _GatedCityRepository extends CityRepository {
  // ignore: use_super_parameters
  _GatedCityRepository(AppDatabase db)
      : super(
          db: db,
          loader: () async => [cairoCity.toJson(), _dubai.toJson()],
        );

  Completer<void>? gate;
  City current = cairoCity;
  int reads = 0;

  @override
  Future<City?> selectedCity() async {
    final result = current;
    reads++;
    final pending = gate;
    if (pending != null) await pending.future;
    return result;
  }
}

class _FixedPrayerTimes implements PrayerTimeService {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
        PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
        PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
        PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
}

void main() {
  test('a city change during an in-flight reload is applied', () async {
    final city = _GatedCityRepository(newTestDb())..gate = Completer<void>();
    final cubit = PrayerTimesCubit(
      prayer: _FixedPrayerTimes(),
      city: city,
    );
    addTearDown(cubit.close);

    final first = cubit.reload();
    await Future<void>.delayed(Duration.zero);

    // The user picks another city while the first read is still in flight.
    city.current = _dubai;
    final second = cubit.reload();

    city.gate!.complete();
    city.gate = null;
    await Future.wait([first, second]);

    final ready = cubit.state as PrayerTimesReady;
    expect(ready.city!.id, 'dubai',
        reason: 'the request made during the load must run after it');
    expect(city.reads, 2);
  });
}
