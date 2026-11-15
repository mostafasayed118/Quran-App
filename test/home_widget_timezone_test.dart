import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/di/injector.dart';
import 'package:quran_yahdi/app/reminder_background_task.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/platform/home_widget_updater.dart';

class _City implements CitySource {
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

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) => const [];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      // 13:30 UTC is 15:30 in Cairo (UTC+2).
      PrayerChoice(PrayerName.fajr, DateTime.utc(2026, 11, 6, 13, 30));
}

class _Updater implements HomeWidgetUpdater {
  String? time;

  @override
  Future<void> update({
    required String appName,
    required String label,
    required String prayer,
    required String time,
    required String city,
  }) async {
    this.time = time;
  }
}

void main() {
  late _Updater updater;

  setUp(() {
    updater = _Updater();
    getIt
      ..registerSingleton<CitySource>(_City())
      ..registerSingleton<PrayerTimesPort>(_Prayer())
      ..registerSingleton<HomeWidgetUpdater>(updater);
  });

  tearDown(() => getIt.reset());

  test('the background widget refresh shows the city clock, not the device one',
      () async {
    await updateHomeWidgetFromState();

    expect(updater.time, '١٥:٣٠',
        reason: 'the prayer instant is 13:30 UTC; the widget must render the '
            'selected city wall clock (UTC+2), as the app card does');
  });
}
