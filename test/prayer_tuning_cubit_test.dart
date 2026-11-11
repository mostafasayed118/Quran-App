import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_state.dart';

class _FakeSource implements PrayerConfigSource {
  PrayerConfig _current = PrayerConfig.egyptian;
  final _changes = StreamController<PrayerConfig>.broadcast();
  int saves = 0;

  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => _changes.stream;

  @override
  Future<PrayerConfig> load() async => _current;

  @override
  Future<void> save(PrayerConfig config) async {
    saves++;
    _current = config;
    _changes.add(config);
  }
}

void main() {
  test('setAdjustment persists a clamped per-prayer correction', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setAdjustment(PrayerName.fajr, 5);
    expect(source.current.adjustmentFor(PrayerName.fajr), 5);

    await cubit.setAdjustment(PrayerName.fajr, 999);
    expect(source.current.adjustmentFor(PrayerName.fajr),
        PrayerConfig.maxAdjustmentMinutes);

    await cubit.setAdjustment(PrayerName.fajr, -999);
    expect(source.current.adjustmentFor(PrayerName.fajr),
        PrayerConfig.minAdjustmentMinutes);

    await cubit.setAdjustment(PrayerName.fajr, 0);
    expect(source.current.adjustmentFor(PrayerName.fajr), 0);
    expect(source.current.adjustments.containsKey(PrayerName.fajr), isFalse);
  });

  test('adjustBy accumulates rapid taps instead of one absolute value',
      () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    final first = cubit.adjustBy(PrayerName.fajr, 1);
    final second = cubit.adjustBy(PrayerName.fajr, 1);
    await Future.wait([first, second]);

    expect(source.current.adjustmentFor(PrayerName.fajr), 2);
    expect(source.saves, 2);
  });

  test('sunrise is rejected without a write', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setAdjustment(PrayerName.sunrise, 5);

    expect(source.saves, 0);
    expect(source.current.adjustments, isEmpty);
  });

  test('setHighLatitude persists the selected rule', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setHighLatitude(PrayerHighLatitudeRule.seventhOfTheNight);

    expect(
        source.current.highLatitude, PrayerHighLatitudeRule.seventhOfTheNight);
    expect(source.saves, 1);

    await cubit.setHighLatitude(PrayerHighLatitudeRule.seventhOfTheNight);
    expect(source.saves, 1);
  });

  test('adjustments and the high-latitude rule survive a reload', () async {
    final source = _FakeSource();
    final first = PrayerConfigCubit(source: source);
    await first.start();
    await first.setAdjustment(PrayerName.isha, -4);
    await first.setHighLatitude(PrayerHighLatitudeRule.middleOfTheNight);
    await first.close();

    final second = PrayerConfigCubit(source: source);
    await second.start();

    final ready = second.state as PrayerConfigReady;
    expect(ready.config.adjustmentFor(PrayerName.isha), -4);
    expect(ready.config.highLatitude, PrayerHighLatitudeRule.middleOfTheNight);
    await second.close();
  });
}
