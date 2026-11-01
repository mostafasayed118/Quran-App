import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_state.dart';

class _FakeSource implements PrayerConfigSource {
  PrayerConfig _current = PrayerConfig.egyptian;
  final _changes = StreamController<PrayerConfig>.broadcast();
  bool throwOnLoad = false;
  bool throwOnSave = false;
  int saves = 0;
  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => _changes.stream;

  @override
  Future<PrayerConfig> load() async {
    if (throwOnLoad) throw StateError('load');
    return _current;
  }

  @override
  Future<void> save(PrayerConfig config) async {
    if (throwOnSave) throw StateError('save');
    saves++;
    _current = config;
    _changes.add(config);
  }
}

class _FakeCanceller implements PreAdhanCanceller {
  int calls = 0;

  @override
  Future<void> cancelPreAdhan() async {
    calls++;
  }
}

void main() {
  test('start loads the persisted configuration', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);

    await cubit.start();

    expect(cubit.state, isA<PrayerConfigReady>());
    final ready = cubit.state as PrayerConfigReady;
    expect(ready.config, PrayerConfig.egyptian);
  });

  test('setters persist and emit once per change', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setMethod(PrayerCalculationMethod.ummAlQura);
    await cubit.setMadhab(PrayerMadhab.hanafi);

    final ready = cubit.state as PrayerConfigReady;
    expect(ready.config.method, PrayerCalculationMethod.ummAlQura);
    expect(ready.config.madhab, PrayerMadhab.hanafi);
    expect(source.saves, 2);
  });

  test('selecting the current value does not write again', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setMethod(PrayerCalculationMethod.egyptian);

    expect(source.saves, 0);
  });

  test('a failed save keeps the last confirmed state', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();
    source.throwOnSave = true;

    await cubit.setMethod(PrayerCalculationMethod.karachi);

    final ready = cubit.state as PrayerConfigReady;
    expect(ready.config.method, PrayerCalculationMethod.egyptian);
  });

  test('a failed load emits failed', () async {
    final source = _FakeSource()..throwOnLoad = true;
    final cubit = PrayerConfigCubit(source: source);

    await cubit.start();

    expect(cubit.state, isA<PrayerConfigFailed>());
  });

  test('overlapping method and madhab selections both persist', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    final method = cubit.setMethod(PrayerCalculationMethod.karachi);
    final madhab = cubit.setMadhab(PrayerMadhab.hanafi);
    await Future.wait([method, madhab]);

    expect(source.current.method, PrayerCalculationMethod.karachi);
    expect(source.current.madhab, PrayerMadhab.hanafi);
    expect(source.saves, 2);
  });

  test('per-prayer toggles and pre-adhan minutes persist', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setPrayerEnabled(PrayerName.fajr, false);
    await cubit.setPrayerEnabled(PrayerName.isha, false);
    await cubit.setPreAdhanMinutes(10);

    expect(source.current.enabledPrayers, isNot(contains(PrayerName.fajr)));
    expect(source.current.enabledPrayers, isNot(contains(PrayerName.isha)));
    expect(source.current.enabledPrayers, contains(PrayerName.dhuhr));
    expect(source.current.preAdhanMinutes, 10);
    expect(source.saves, 3);
  });

  test('pre-adhan minutes are clamped to the supported range', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await cubit.setPreAdhanMinutes(999);
    expect(source.current.preAdhanMinutes, 60);

    await cubit.setPreAdhanMinutes(-5);
    expect(source.current.preAdhanMinutes, 0);
  });

  test('turning the pre-adhan off clears the OS alarm', () async {
    final source = _FakeSource();
    final canceller = _FakeCanceller();
    final cubit = PrayerConfigCubit(
      source: source,
      preAdhanCanceller: canceller,
    );
    await cubit.start();

    await cubit.setPreAdhanMinutes(10);
    expect(canceller.calls, 0);

    await cubit.setPreAdhanMinutes(0);
    expect(canceller.calls, 1);
  });

  test('setters before the first load are dropped', () async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);

    await cubit.setMethod(PrayerCalculationMethod.karachi);

    expect(cubit.state, isA<PrayerConfigLoading>());
    expect(source.saves, 0);
  });
}
