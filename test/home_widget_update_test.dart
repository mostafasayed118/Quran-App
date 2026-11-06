import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/platform/home_widget_updater.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';

class _LastRead implements LastReadMarker {
  @override
  Future<int?> loadAyahId() async => null;
}

class _Ayahs implements AyahLookup {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => const [];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.asr, DateTime(2026, 11, 6, 15, 30));
}

class _City implements CitySource {
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

class _Updater implements HomeWidgetUpdater {
  String? appName;
  String? label;
  String? prayer;
  String? time;
  String? city;
  int calls = 0;

  @override
  Future<void> update({
    required String appName,
    required String label,
    required String prayer,
    required String time,
    required String city,
  }) async {
    calls += 1;
    this.appName = appName;
    this.label = label;
    this.prayer = prayer;
    this.time = time;
    this.city = city;
  }
}

void main() {
  test('the home load mirrors the next prayer into the widget', () async {
    final updater = _Updater();
    final cubit = HomeCubit(
      lastRead: _LastRead(),
      ayahs: _Ayahs(),
      prayer: _Prayer(),
      city: _City(),
      widgetUpdater: updater,
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect(updater.calls, 1);
    expect(updater.appName, isNotEmpty);
    expect(updater.label, 'الصلاة القادمة');
    expect(updater.prayer, 'العصر');
    expect(updater.time, '١٥:٣٠');
    expect(updater.city, 'القاهرة');
  });

  test('without a selected city the widget is not touched', () async {
    final updater = _Updater();
    final cubit = HomeCubit(
      lastRead: _LastRead(),
      ayahs: _Ayahs(),
      prayer: _Prayer(),
      city: _NoCity(),
      widgetUpdater: updater,
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect(updater.calls, 0);
  });
}

class _NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;

  @override
  Future<void> select(City city) async {}
}
