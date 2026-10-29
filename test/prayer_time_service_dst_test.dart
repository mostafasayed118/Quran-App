import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

/// Regression guard for the DST-end defect: `nextPrayer` used `day.add(const
/// Duration(days: 1))` for the after-Isha wrap. On a DST-end day (Egypt:
/// 2026-10-29) +24 h lands back on the SAME calendar date, so the "next"
/// prayer was today's already-passed fajr.
///
/// The assertions are timezone-relative (the service computes in the host
/// timezone), so they reproduce the bug on a device/host set to
/// Africa/Cairo and pass trivially on a UTC host.
void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  const service = PrayerTimeService();

  test('after isha the next prayer is strictly in the future (DST-end day)',
      () {
    final lateNight = DateTime(2026, 10, 29, 21, 26);
    final next = service.nextPrayer(cairo, lateNight);

    expect(
      next.time.isAfter(lateNight),
      isTrue,
      reason: 'next prayer ${next.time} must be after $lateNight',
    );
    expect(next.name, PrayerName.fajr);
  });

  test('after isha the next prayer is tomorrow, never today', () {
    final lateNight = DateTime(2026, 10, 29, 23, 50);
    final next = service.nextPrayer(cairo, lateNight);

    final nextDay = DateTime(
      next.time.year,
      next.time.month,
      next.time.day,
    );
    final today = DateTime(
      lateNight.year,
      lateNight.month,
      lateNight.day,
    );
    expect(next.time.isAfter(lateNight), isTrue);
    expect(nextDay, isNot(today));
  });
}
