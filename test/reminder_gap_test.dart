import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';

class _NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;
  @override
  Future<void> select(City city) async {}
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

class _Prayer implements PrayerTimesPort {
  _Prayer({List<PrayerChoice> today = const <PrayerChoice>[]})
      : todayPrayers = today;

  final List<PrayerChoice> todayPrayers;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      todayPrayers;
  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
}

class _Settings implements ReminderSettingsPort {
  @override
  Future<bool> azkarEnabled() async => true;
  @override
  Future<String?> azkarTimeHm() async => '06:30';
  @override
  Future<bool> wirdEnabled() async => true;
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

ReminderTexts _texts() => ReminderTexts(
      prayerTitle: (name) => 'prayer ${name.name}',
      azkarTitle: 'azkar',
      wirdTitle: 'wird',
    );

void main() {
  test('after Isha the plan uses the supplied next prayer (tomorrow Fajr)', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 21, 0),
      todayPrayers: [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ],
      nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45)),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan, hasLength(1));
    expect(plan.single.id, prayerReminderId);
    expect(plan.single.fireAt, DateTime(2026, 3, 16, 4, 45));
  });

  test('no city still schedules azkar and wird', () async {
    final scheduler = _Scheduler();
    await scheduleReminders(
      city: _NoCity(),
      prayer: _Prayer(),
      settings: _Settings(),
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 5, 0),
    );

    final ids = scheduler.plan!.map((r) => r.id).toSet();
    expect(ids, containsAll({azkarReminderId, wirdReminderId}));
    expect(ids, isNot(contains(prayerReminderId)));
  });

  test('a selected city after Isha schedules tomorrow Fajr from the port',
      () async {
    final scheduler = _Scheduler();
    await scheduleReminders(
      city: _OneCity(),
      prayer: _Prayer(today: [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ]),
      settings: _Settings(),
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 21, 0),
    );

    final plan = scheduler.plan!;
    expect(plan.map((r) => r.id).toSet(), {1, 2, 3});
    final prayer = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.fireAt, DateTime(2026, 3, 16, 4, 45));
  });
}
