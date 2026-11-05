import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';

void main() {
  test('the historical defaults add no adjustment and no high-latitude rule',
      () {
    expect(PrayerConfig.egyptian.adjustments, isEmpty);
    expect(PrayerConfig.egyptian.highLatitude, PrayerHighLatitudeRule.none);
    expect(PrayerConfig.egyptian.adjustmentFor(PrayerName.fajr), 0);
  });

  test('adjustments and the high-latitude rule round-trip through JSON', () {
    const config = PrayerConfig(
      adjustments: {
        PrayerName.fajr: 5,
        PrayerName.isha: -3,
      },
      highLatitude: PrayerHighLatitudeRule.seventhOfTheNight,
    );

    final decoded = PrayerConfig.fromJson(config.toJson());

    expect(decoded, config);
    expect(decoded.adjustmentFor(PrayerName.fajr), 5);
    expect(decoded.adjustmentFor(PrayerName.isha), -3);
    expect(decoded.highLatitude, PrayerHighLatitudeRule.seventhOfTheNight);
  });

  test('malformed, unknown and out-of-range adjustments are clamped or dropped',
      () {
    final decoded = PrayerConfig.fromJson(const {
      PrayerConfig.adjustmentsKey:
          'fajr:999,isha:-999,sunrise:5,dhuhr:0,unknown:4,garbage',
      PrayerConfig.highLatitudeKey: 'not-a-rule',
    });

    expect(decoded.adjustmentFor(PrayerName.fajr),
        PrayerConfig.maxAdjustmentMinutes);
    expect(decoded.adjustmentFor(PrayerName.isha),
        PrayerConfig.minAdjustmentMinutes);
    expect(decoded.adjustments.containsKey(PrayerName.sunrise), isFalse);
    expect(decoded.adjustmentFor(PrayerName.dhuhr), 0);
    expect(decoded.highLatitude, PrayerHighLatitudeRule.none);
  });

  test('zero entries never reach the persisted map', () {
    const config = PrayerConfig(
      adjustments: {PrayerName.asr: 0, PrayerName.maghrib: 4},
    );

    expect(config.toJson()[PrayerConfig.adjustmentsKey], 'maghrib:4');
  });

  test('equality is order-independent for the adjustment map', () {
    const a = PrayerConfig(
      adjustments: {PrayerName.fajr: 2, PrayerName.isha: 4},
    );
    const b = PrayerConfig(
      adjustments: {PrayerName.isha: 4, PrayerName.fajr: 2},
    );
    const c = PrayerConfig(adjustments: {PrayerName.fajr: 2});

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
