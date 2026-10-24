import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

class GatedSettings implements ReminderSettingsPort {
  final Completer<void> azkarGate = Completer<void>();
  int azkarWriteCalls = 0;
  int azkarTimeWriteCalls = 0;
  bool azkar = false;
  String azkarTime = defaultAzkarTimeHm;
  bool wird = false;
  String wirdTime = defaultWirdTimeHm;

  @override
  Future<bool> azkarEnabled() async => azkar;

  @override
  Future<String?> azkarTimeHm() async => azkarTime;

  @override
  Future<bool> wirdEnabled() async => wird;

  @override
  Future<String?> wirdTimeHm() async => wirdTime;

  @override
  Future<void> setAzkarEnabled(bool enabled) async {
    azkarWriteCalls++;
    await azkarGate.future;
    azkar = enabled;
  }

  @override
  Future<void> setAzkarTime(String hm) async {
    azkarTimeWriteCalls++;
    azkarTime = hm;
  }

  @override
  Future<void> setWirdEnabled(bool enabled) async {
    wird = enabled;
  }

  @override
  Future<void> setWirdTime(String hm) async {
    wirdTime = hm;
  }

  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {}
}

class NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;

  @override
  Future<void> select(City city) async {}
}

class NoPrayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      const <PrayerChoice>[];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, whenLocal);
}

class NoScheduler implements ReminderSchedulerPort {
  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {}
}

void main() {
  test('overlapping setters serialize and keep both fields', () async {
    final settings = GatedSettings();
    final cubit = SettingsCubit(
      settings: settings,
      city: NoCity(),
      prayer: NoPrayer(),
      scheduler: NoScheduler(),
    );
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<SettingsReady>());

    final azkar = cubit.setAzkarEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(settings.azkarWriteCalls, 1);

    final time = cubit.setTime('05:15');
    await Future<void>.delayed(Duration.zero);
    expect(settings.azkarTimeWriteCalls, 0);

    settings.azkarGate.complete();
    await azkar;
    await time;

    final ready = cubit.state as SettingsReady;
    expect(ready.azkarEnabled, isTrue);
    expect(ready.azkarTimeHm, '05:15');

    await cubit.close();
  });
}
