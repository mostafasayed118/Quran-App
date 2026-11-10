import 'package:adhan/adhan.dart' show HighLatitudeRule;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_calculator.dart';

void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  final day = DateTime(2026, 11, 1);

  test('every method x high-latitude rule computes without throwing', () {
    for (final method in PrayerCalculationMethod.values) {
      for (final rule in PrayerHighLatitudeRule.values) {
        final config = PrayerConfig(method: method, highLatitude: rule);
        expect(
          () => prayerTimesFor(cairo, day, config),
          returnsNormally,
          reason: '$method + $rule',
        );
      }
    }
  });

  test('twilight angle falls back for methods without an Isha angle', () {
    for (final method in [
      PrayerCalculationMethod.ummAlQura,
      PrayerCalculationMethod.qatar,
    ]) {
      final params = parametersFor(PrayerConfig(
        method: method,
        highLatitude: PrayerHighLatitudeRule.twilightAngle,
      ));
      expect(
        params.highLatitudeRule,
        HighLatitudeRule.seventh_of_the_night,
        reason: '$method must not keep an unsupported twilight rule',
      );
    }
  });

  test('twilight angle is kept for methods that define an Isha angle', () {
    final params = parametersFor(const PrayerConfig(
      method: PrayerCalculationMethod.egyptian,
      highLatitude: PrayerHighLatitudeRule.twilightAngle,
    ));
    expect(params.highLatitudeRule, HighLatitudeRule.twilight_angle);
  });
}
