import 'package:adhan/adhan.dart' show Madhab;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_calculator.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  final day = DateTime(2026, 11, 1);

  test('the Egyptian config reproduces the shipped service exactly', () {
    final shipped = const PrayerTimeService().today(cairo, day);
    final configured = prayerTimesFor(cairo, day, PrayerConfig.egyptian);

    expect(configured.map((e) => e.name), shipped.map((e) => e.name));
    for (var i = 0; i < shipped.length; i++) {
      expect(configured[i].time, shipped[i].time, reason: 'entry $i');
    }
  });

  test('a different method moves at least one time', () {
    final egyptian = prayerTimesFor(cairo, day, PrayerConfig.egyptian);
    final mwl = prayerTimesFor(
      cairo,
      day,
      const PrayerConfig(method: PrayerCalculationMethod.muslimWorldLeague),
    );

    expect(
      mwl.map((e) => e.time).toList(),
      isNot(equals(egyptian.map((e) => e.time).toList())),
    );
  });

  test('the Hanafi madhab moves only Asr later', () {
    final shafi = prayerTimesFor(cairo, day, PrayerConfig.egyptian);
    final hanafi = prayerTimesFor(
      cairo,
      day,
      const PrayerConfig(madhab: PrayerMadhab.hanafi),
    );

    expect(hanafi[3].time.isAfter(shafi[3].time), isTrue,
        reason: 'Asr must be later under Hanafi');
    for (final index in [0, 1, 2, 4, 5]) {
      expect(hanafi[index].time, shafi[index].time, reason: 'entry $index');
    }
  });

  test('nextPrayerAfter wraps to tomorrow fajr after Isha', () {
    final entries = prayerTimesFor(cairo, day, PrayerConfig.egyptian);
    final afterIsha = entries.last.time.add(const Duration(minutes: 1));

    final next = nextPrayerAfter(cairo, afterIsha, PrayerConfig.egyptian);

    expect(next.name, PrayerName.fajr);
    expect(next.time.day, day.day + 1);
    expect(next.time.isAfter(afterIsha), isTrue);
  });

  test('every method maps to its own adhan parameters', () {
    for (final method in PrayerCalculationMethod.values) {
      final parameters = parametersFor(PrayerConfig(method: method));
      expect(parameters.madhab, Madhab.shafi);
      expect(parameters.method.name, isNotEmpty);
    }
    final hanafi = parametersFor(
      const PrayerConfig(madhab: PrayerMadhab.hanafi),
    );
    expect(hanafi.madhab, Madhab.hanafi);
  });
}
