import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart' show PrayerName;
import 'package:quran_yahdi/features/prayer/data/configured_prayer_times.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';

/// RED for the corrected H-1: the prayer-times DAY must come from the selected
/// city's timezone, not the device's.
///
/// Scenario: device clock reads 23:30 on 2026-11-17 (UTC device — day D).
/// The selected city is Cairo (UTC+2), where the same instant is 01:30 on
/// 2026-11-18 (day D+1). "Today's prayers" must be day D+1's; the current code
/// builds day D's from the device-local `DateTime.now()`, which is 24 h early.
class _CityCairo implements CitySource {
  const _CityCairo();

  @override
  Future<City?> selectedCity() async => const City(
    id: 'cairo',
    nameAr: 'القاهرة',
    nameEn: 'Cairo',
    lat: 30.0444,
    lng: 31.2357,
    timezone: 'Africa/Cairo',
  );

  @override
  Future<void> select(City city) async {}
}

class _Config implements PrayerConfigSource {
  const _Config();

  @override
  PrayerConfig get current => PrayerConfig.egyptian;

  @override
  Stream<PrayerConfig> get changes => const Stream.empty();

  @override
  Future<PrayerConfig> load() async => PrayerConfig.egyptian;

  @override
  Future<void> save(PrayerConfig config) async {}
}

void main() {
  test('prayer-times day follows the city zone near midnight', () async {
    final cubit = PrayerTimesCubit(
      prayer: ConfiguredPrayerTimes(const _Config()),
      city: const _CityCairo(),
      // Device-local "now": 23:30 on 2026-11-17. In Cairo this is already
      // 01:30 on 2026-11-18, so the correct day is 18, not 17.
      clock: () => DateTime.utc(2026, 11, 17, 23, 30),
    );
    await cubit.reload();

    final state = cubit.state as PrayerTimesReady;
    final fajr = state.entries.firstWhere((e) => e.name == PrayerName.fajr);
    // Cairo Fajr for 2026-11-18 is ~03:xx UTC; for 2026-11-17 it is 24 h
    // earlier. Current code yields the 17th — the bug this test must catch.
    expect(
      fajr.time.toUtc().day,
      18,
      reason: 'the day must follow the city date (D+1), not device date (D)',
    );

    await cubit.close();
  });
}
