import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';

import 'support/test_db.dart';

class FakePrayerTimeService implements PrayerTimeService {
  List<PrayerChoice>? todayResult;
  PrayerChoice? nextResult;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      todayResult!;

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) => nextResult!;
}

const cairoCity = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

const dubaiCity = City(
  id: 'dubai',
  nameAr: 'دبي',
  nameEn: 'Dubai',
  lat: 25.2048,
  lng: 55.2708,
);

List<PrayerChoice> fakeDay() => [
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
      PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
      PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
      PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
      PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
      PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
    ];

void main() {
  late AppDatabase db;
  late CityRepository repo;
  late FakePrayerTimeService fake;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(
        db: db, loader: () async => [cairoCity.toJson(), dubaiCity.toJson()]);
    fake = FakePrayerTimeService()
      ..todayResult = fakeDay()
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
  });

  test('no selection emits ready with no city and empty entries', () async {
    final cubit = PrayerTimesCubit(prayer: fake, city: repo);
    await cubit.reload();

    final state = cubit.state;
    expect(state, isA<PrayerTimesReady>());
    final ready = state as PrayerTimesReady;
    expect(ready.city, isNull);
    expect(ready.entries, isEmpty);

    await cubit.close();
  });

  test('with selection: entries ordered with times and the next anchor flagged',
      () async {
    await repo.select(cairoCity);
    final cubit = PrayerTimesCubit(prayer: fake, city: repo);
    await cubit.reload();

    final ready = cubit.state as PrayerTimesReady;
    expect(ready.city!.id, 'cairo');
    expect(ready.entries.map((e) => e.name), PrayerName.values);
    final nextList = ready.entries.where((e) => e.isNext).toList();
    expect(nextList, hasLength(1));
    expect(nextList.single.name, PrayerName.asr);
    expect(nextList.single.time, DateTime(2026, 3, 15, 15, 35));

    await cubit.close();
  });
}
