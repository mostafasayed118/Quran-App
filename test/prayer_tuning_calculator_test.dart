import 'package:adhan/adhan.dart' show HighLatitudeRule;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_calculator.dart';

void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  final day = DateTime(2026, 11, 1);

  test('per-prayer adjustments map into the adhan parameters', () {
    final params = parametersFor(const PrayerConfig(
      adjustments: {
        PrayerName.fajr: 5,
        PrayerName.dhuhr: -2,
        PrayerName.isha: 7,
      },
    ));

    expect(params.adjustments.fajr, 5);
    expect(params.adjustments.dhuhr, -2);
    expect(params.adjustments.isha, 7);
    expect(params.adjustments.asr, 0);
    expect(params.adjustments.maghrib, 0);
  });

  test('a Fajr adjustment moves only Fajr in the computed day', () {
    final base = prayerTimesFor(cairo, day, PrayerConfig.egyptian);
    final tuned = prayerTimesFor(
      cairo,
      day,
      const PrayerConfig(adjustments: {PrayerName.fajr: 5}),
    );

    expect(tuned[0].time, base[0].time.add(const Duration(minutes: 5)));
    for (final index in [1, 2, 3, 4, 5]) {
      expect(tuned[index].time, base[index].time, reason: 'entry $index');
    }
  });

  test('every high-latitude rule maps to its adhan enum', () {
    expect(
      parametersFor(const PrayerConfig(
        highLatitude: PrayerHighLatitudeRule.middleOfTheNight,
      )).highLatitudeRule,
      HighLatitudeRule.middle_of_the_night,
    );
    expect(
      parametersFor(const PrayerConfig(
        highLatitude: PrayerHighLatitudeRule.seventhOfTheNight,
      )).highLatitudeRule,
      HighLatitudeRule.seventh_of_the_night,
    );
    expect(
      parametersFor(const PrayerConfig(
        highLatitude: PrayerHighLatitudeRule.twilightAngle,
      )).highLatitudeRule,
      HighLatitudeRule.twilight_angle,
    );
  });

  test('the none rule keeps the method default', () {
    final defaultRule = parametersFor(PrayerConfig.egyptian).highLatitudeRule;
    final none = parametersFor(const PrayerConfig(
      highLatitude: PrayerHighLatitudeRule.none,
    )).highLatitudeRule;

    expect(none, defaultRule);
  });

  test('a high-latitude rule changes Fajr at a summer London latitude', () {
    const london = CityCoordinates(51.5074, -0.1278);
    final summer = DateTime(2026, 6, 21);
    final base = prayerTimesFor(london, summer, PrayerConfig.egyptian);
    final seventh = prayerTimesFor(
      london,
      summer,
      const PrayerConfig(
        highLatitude: PrayerHighLatitudeRule.seventhOfTheNight,
      ),
    );

    expect(
      (seventh[0].time, seventh[5].time),
      isNot((base[0].time, base[5].time)),
    );
  });
}
