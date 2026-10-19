import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  const service = PrayerTimeService();

  test(
      'ordering: fajr < sunrise < dhuhr < asr < maghrib < isha for Cairo on a sample day',
      () {
    final entries = service.today(cairo, DateTime(2026, 3, 15));
    expect(entries.map((e) => e.name).toList(), PrayerName.values);
    for (var i = 1; i < entries.length; i++) {
      expect(entries[i].time.isAfter(entries[i - 1].time), isTrue,
          reason: '${entries[i - 1].name} !< ${entries[i].name}');
    }
  });

  test(
      'allsanity: sunrise-fajr between 60 and 160 minutes; isha-maghrib between 60 and 130 minutes (egyptian method)',
      () {
    final entries = service.today(cairo, DateTime(2026, 3, 15));
    final byName = {for (final e in entries) e.name: e.time};
    final fajrToSunrise = byName[PrayerName.sunrise]!
        .difference(byName[PrayerName.fajr]!)
        .inMinutes;
    final maghribToIsha = byName[PrayerName.isha]!
        .difference(byName[PrayerName.maghrib]!)
        .inMinutes;
    expect(fajrToSunrise, inInclusiveRange(60, 160));
    expect(maghribToIsha, inInclusiveRange(60, 130));
  });

  test(
      'nextPrayer picks strictly-after first anchor; after isha wraps to tomorrow fajr',
      () {
    final day = DateTime(2026, 3, 15);
    final entries = service.today(cairo, day);
    final byName = {for (final e in entries) e.name: e.time};

    final between = byName[PrayerName.dhuhr]!.add(const Duration(minutes: 15));
    final choice = service.nextPrayer(cairo, between);
    expect(choice.name, PrayerName.asr);
    expect(choice.time.isAfter(between), isTrue);

    final lateNight = DateTime(2026, 3, 15, 23, 50);
    final wrap = service.nextPrayer(cairo, lateNight);
    expect(wrap.name, PrayerName.fajr);
    expect(wrap.time.isAfter(lateNight), isTrue);
    expect(wrap.time.day, 16);
  });

  test('egyptian method is the fixed v1 default', () {
    expect(PrayerTimeService.methodLabel, 'egyptian');
  });
}
