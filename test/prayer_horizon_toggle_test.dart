import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';

List<PrayerChoice> _day(DateTime day) => <PrayerChoice>[
      PrayerChoice(
          PrayerName.fajr, DateTime(day.year, day.month, day.day, 4, 45)),
      PrayerChoice(
          PrayerName.sunrise, DateTime(day.year, day.month, day.day, 6, 10)),
      PrayerChoice(
          PrayerName.dhuhr, DateTime(day.year, day.month, day.day, 12, 5)),
      PrayerChoice(
          PrayerName.asr, DateTime(day.year, day.month, day.day, 15, 35)),
      PrayerChoice(
          PrayerName.maghrib, DateTime(day.year, day.month, day.day, 18, 5)),
      PrayerChoice(
          PrayerName.isha, DateTime(day.year, day.month, day.day, 19, 30)),
    ];

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

class _DayPrayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      _day(dayLocal);
  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, _day(whenLocal)[0].time);
}

class _Settings implements ReminderSettingsPort {
  @override
  Future<bool> azkarEnabled() async => false;
  @override
  Future<String?> azkarTimeHm() async => null;
  @override
  Future<bool> wirdEnabled() async => false;
  @override
  Future<String?> wirdTimeHm() async => null;
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
  }) async {}
}

class _Scheduler implements ReminderSchedulerPort {
  List<ScheduledReminder>? plan;
  @override
  Future<bool> ensurePermissions() async => true;
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    plan = List<ScheduledReminder>.of(reminders);
  }
}

void main() {
  final now = DateTime(2026, 3, 15, 0, 30);

  Future<List<ScheduledReminder>> run({required bool prayerEnabled}) async {
    final scheduler = _Scheduler();
    await scheduleReminders(
      city: _City(),
      prayer: _DayPrayer(),
      settings: _Settings(),
      scheduler: scheduler,
      prayerEnabled: prayerEnabled,
      now: now,
    );
    return scheduler.plan ?? const <ScheduledReminder>[];
  }

  test('prayer reminders off suppresses the whole 7-day horizon', () async {
    final plan = await run(prayerEnabled: false);
    expect(
      plan.where((r) => r.payload == prayerReminderPayload),
      isEmpty,
      reason: 'the master switch must silence today and the horizon',
    );
  });

  test('prayer reminders on still schedules the horizon', () async {
    final plan = await run(prayerEnabled: true);
    expect(
      plan.where((r) => r.payload == prayerReminderPayload),
      isNotEmpty,
    );
  });
}
