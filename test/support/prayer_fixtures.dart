import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';

export 'fake_prayer_time_service.dart' show FakePrayerTimeService;

/// A city whose zone differs from the usual test host, for zone-sensitive
/// scheduling tests.
const dubaiCity = City(
  id: 'dubai',
  nameAr: 'دبي',
  nameEn: 'Dubai',
  lat: 25.2048,
  lng: 55.2708,
);

/// A fixed, ordinary prayer day.
List<PrayerChoice> fakeDay() => [
  PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
  PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
  PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
  PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
  PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
  PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
];

/// The same six prayers on an arbitrary calendar day.
List<PrayerChoice> dayOn(int y, int m, int d) => [
  PrayerChoice(PrayerName.fajr, DateTime(y, m, d, 4, 45)),
  PrayerChoice(PrayerName.sunrise, DateTime(y, m, d, 6, 10)),
  PrayerChoice(PrayerName.dhuhr, DateTime(y, m, d, 12, 5)),
  PrayerChoice(PrayerName.asr, DateTime(y, m, d, 15, 35)),
  PrayerChoice(PrayerName.maghrib, DateTime(y, m, d, 18, 5)),
  PrayerChoice(PrayerName.isha, DateTime(y, m, d, 19, 30)),
];

/// No selected city.
class NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;

  @override
  Future<void> select(City city) async {}
}

/// No prayer rows, and a prayer at the caller's instant.
class NoPrayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      const <PrayerChoice>[];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, whenLocal);
}
