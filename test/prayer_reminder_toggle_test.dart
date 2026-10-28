import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'support/test_db.dart';

class _NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;
  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      const <PrayerChoice>[];
  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
}

class _Settings implements ReminderSettingsPort {
  int rescheduleCalls = 0;

  @override
  Future<bool> azkarEnabled() async => false;
  @override
  Future<String?> azkarTimeHm() async => '06:30';
  @override
  Future<bool> wirdEnabled() async => false;
  @override
  Future<String?> wirdTimeHm() async => '20:00';
  @override
  Future<void> setAzkarEnabled(bool enabled) async {}
  @override
  Future<void> setAzkarTime(String hm) async {}
  @override
  Future<void> setWirdEnabled(bool enabled) async {}
  @override
  Future<void> setWirdTime(String hm) async {}
  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {
    rescheduleCalls++;
  }
}

class _PrayerSettings implements PrayerReminderSettingsPort {
  bool stored = true;
  int writes = 0;

  @override
  Future<bool> prayerEnabled() async => stored;
  @override
  Future<void> setPrayerEnabled(bool enabled) async {
    writes++;
    stored = enabled;
  }
}

class _Scheduler implements ReminderSchedulerPort {
  @override
  Future<bool> ensurePermissions() async => true;
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {}
}

ReminderTexts _texts() => ReminderTexts(
      prayerTitle: (name) => 'prayer ${name.name}',
      azkarTitle: 'azkar',
      wirdTitle: 'wird',
    );

void main() {
  group('planReminders prayer toggle', () {
    test('prayerEnabled: false drops the prayer reminder, keeps azkar', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 12, 0),
        todayPrayers: [
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 30)),
        ],
        nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45)),
        prayerEnabled: false,
        azkarEnabled: true,
        azkarTimeHm: '06:30',
        texts: _texts(),
      );

      final ids = plan.map((r) => r.id).toSet();
      expect(ids, isNot(contains(prayerReminderId)));
      expect(ids, contains(azkarReminderId));
    });

    test('prayerEnabled: true still schedules the prayer reminder', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 12, 0),
        todayPrayers: [
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 30)),
        ],
        nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45)),
        prayerEnabled: true,
        azkarEnabled: false,
        azkarTimeHm: null,
        texts: _texts(),
      );

      final prayer = plan.singleWhere((r) => r.id == prayerReminderId);
      expect(prayer.fireAt, DateTime(2026, 3, 15, 15, 30));
      expect(prayer.payload, prayerReminderPayload);
    });
  });

  test('ReminderSettings defaults the prayer reminder to enabled and persists',
      () async {
    final settings = ReminderSettings(newTestDb());

    expect(await settings.prayerEnabled(), isTrue);

    await settings.setPrayerEnabled(false);
    expect(await settings.prayerEnabled(), isFalse);

    await settings.setPrayerEnabled(true);
    expect(await settings.prayerEnabled(), isTrue);
  });

  test('SettingsCubit toggles the prayer flag, persists and re-plans',
      () async {
    final settings = _Settings();
    final prayerSettings = _PrayerSettings();
    final cubit = SettingsCubit(
      settings: settings,
      prayerSettings: prayerSettings,
      city: _NoCity(),
      prayer: _Prayer(),
      scheduler: _Scheduler(),
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect((cubit.state as SettingsReady).prayerEnabled, isTrue);

    await cubit.setPrayerEnabled(false);

    expect(prayerSettings.stored, isFalse);
    expect(prayerSettings.writes, 1);
    expect((cubit.state as SettingsReady).prayerEnabled, isFalse);
    expect(settings.rescheduleCalls, 1);

    // Another reminder toggle must not reset the prayer flag.
    await cubit.setAzkarEnabled(true);
    expect((cubit.state as SettingsReady).prayerEnabled, isFalse);
  });
}
