import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';

class _NoLastRead implements LastReadMarker {
  @override
  Future<int?> loadAyahId() async => null;
}

class _NoAyahs implements AyahLookup {
  @override
  Future<Ayah?> ayahById(int ayahId) async => null;

  @override
  Future<List<Ayah>> ayahsForRange(
          int surahId, int fromAyah, int toAyah) async =>
      const <Ayah>[];

  @override
  Future<Surah?> surahById(int surahId) async => null;
}

class _OneCity implements CitySource {
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

class _AdvancingPrayer implements PrayerTimesPort {
  int calls = 0;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      const <PrayerChoice>[];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    calls++;
    final time = calls == 1
        ? DateTime.now().add(const Duration(seconds: 30))
        : DateTime.now().add(const Duration(hours: 1));
    return PrayerChoice(PrayerName.fajr, time);
  }
}

void main() {
  testWidgets('home re-plans when the shown prayer time passes',
      (tester) async {
    final prayer = _AdvancingPrayer();
    final cubit = HomeCubit(
      lastRead: _NoLastRead(),
      ayahs: _NoAyahs(),
      prayer: prayer,
      city: _OneCity(),
    );

    await cubit.start();
    expect(prayer.calls, 1);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump();

    expect(prayer.calls, 2);
    await cubit.close();
  });
}
