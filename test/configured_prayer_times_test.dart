import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart' show PrayerName;
import 'package:quran_yahdi/features/prayer/data/configured_prayer_times.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_calculator.dart';

class _FakeSource implements PrayerConfigSource {
  PrayerConfig _current = PrayerConfig.egyptian;
  final _changes = StreamController<PrayerConfig>.broadcast();

  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => _changes.stream;

  @override
  Future<PrayerConfig> load() async => _current;

  @override
  Future<void> save(PrayerConfig config) async {
    _current = config;
    _changes.add(config);
  }
}

void main() {
  const cairo = CityCoordinates(30.0444, 31.2357);
  final day = DateTime(2026, 11, 1);

  test('configured port delegates to the calculator with the cached config',
      () {
    final source = _FakeSource();
    final port = ConfiguredPrayerTimes(source);

    final configured = port.today(cairo, day);
    final expected = prayerTimesFor(cairo, day, PrayerConfig.egyptian);

    expect(configured.map((e) => e.name), expected.map((e) => e.name));
    for (var i = 0; i < configured.length; i++) {
      expect(configured[i].time, expected[i].time);
    }
  });

  test('a changed source changes the next computed times', () async {
    final source = _FakeSource();
    final port = ConfiguredPrayerTimes(source);
    final before = port.today(cairo, day);
    await source.save(
      const PrayerConfig(method: PrayerCalculationMethod.muslimWorldLeague),
    );
    final after = port.today(cairo, day);

    expect(
      after.map((e) => e.time).toList(),
      isNot(equals(before.map((e) => e.time).toList())),
    );
  });

  test('nextPrayer uses the configured method and wraps after Isha', () {
    final source = _FakeSource();
    final port = ConfiguredPrayerTimes(source);
    final entries = port.today(cairo, day);
    final afterIsha = entries.last.time.add(const Duration(minutes: 1));

    final next = port.nextPrayer(cairo, afterIsha);

    expect(next.name, PrayerName.fajr);
    expect(next.time.day, day.day + 1);
  });
}
