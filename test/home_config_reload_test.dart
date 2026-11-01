import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_state.dart';

class _NoLastRead implements LastReadMarker {
  @override
  Future<int?> loadAyahId() async => null;
}

class _NoAyahs implements AyahLookup {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _City implements CitySource {
  const _City();

  @override
  Future<City?> selectedCity() async => const City(
        id: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        lat: 30.0444,
        lng: 31.2357,
      );

  @override
  Future<void> select(City city) async {}
}

class _CountingPrayer implements PrayerTimesPort {
  int calls = 0;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => const [];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    calls++;
    return PrayerChoice(
      PrayerName.dhuhr,
      DateTime.now().add(Duration(hours: calls)),
    );
  }
}

void main() {
  test('a prayer config change reloads the home cards', () async {
    final prayer = _CountingPrayer();
    final changes = StreamController<PrayerConfig>.broadcast();
    final cubit = HomeCubit(
      lastRead: _NoLastRead(),
      ayahs: _NoAyahs(),
      prayer: prayer,
      city: const _City(),
      configChanges: changes.stream,
    );
    addTearDown(() async {
      await cubit.close();
      await changes.close();
    });

    await cubit.start();
    expect(cubit.state, isA<HomeReady>());
    expect(prayer.calls, 1);

    changes.add(const PrayerConfig(method: PrayerCalculationMethod.karachi));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(prayer.calls, 2);
    expect(cubit.state, isA<HomeReady>());
  });
}
