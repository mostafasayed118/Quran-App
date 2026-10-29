import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

import 'prayer_times_cubit_test.dart'
    show FakePrayerTimeService, cairoCity, fakeDay;

class _CapturingScheduler implements ReminderSchedulerPort {
  final plans = <List<ScheduledReminder>>[];

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    plans.add(reminders);
  }
}

ReminderTexts _texts({String? wirdTitle = 'ورد الختمة', String? wirdBody}) =>
    ReminderTexts(
      prayerTitle: (name) => 'حان موعد صلاة ${name.name}',
      azkarTitle: 'أذكار الصباح',
      wirdTitle: wirdTitle,
      wirdBody: wirdBody,
    );

void main() {
  test('wird schedules today while its time is still ahead', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: _texts(),
    );

    final wird = plan.singleWhere((r) => r.id == wirdReminderId);
    expect(wird.fireAt, DateTime(2026, 3, 15, 20, 0));
    expect(wird.title, 'ورد الختمة');
    expect(wird.body, isNull);
    expect(wird.payload, wirdReminderPayload);
  });

  test('wird rolls to tomorrow once its time has passed', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 21, 0),
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: _texts(),
    );

    expect(
      plan.singleWhere((r) => r.id == wirdReminderId).fireAt,
      DateTime(2026, 3, 16, 20, 0),
    );
  });

  test('disabled or title-less wird stays out of the plan', () {
    final disabled = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: false,
      texts: _texts(),
    );
    expect(disabled.where((r) => r.id == wirdReminderId), isEmpty);

    final untitled = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: true,
      texts: _texts(wirdTitle: null),
    );
    expect(untitled.where((r) => r.id == wirdReminderId), isEmpty);
  });

  test('null or malformed wird time falls back to the 20:00 default', () {
    for (final hm in <String?>[null, '25:99']) {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 10, 0),
        todayPrayers: const <PrayerChoice>[],
        azkarEnabled: false,
        azkarTimeHm: null,
        wirdEnabled: true,
        wirdTimeHm: hm,
        texts: _texts(),
      );
      expect(
        plan.singleWhere((r) => r.id == wirdReminderId).fireAt,
        DateTime(2026, 3, 15, 20, 0),
        reason: 'fallback for $hm',
      );
    }
  });

  test('a provided wird body passes through', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: _texts(wirdBody: 'واصل ختمتك'),
    );

    expect(
      plan.singleWhere((r) => r.id == wirdReminderId).body,
      'واصل ختمتك',
    );
  });

  test('prayer, azkar and wird coexist with unique ids', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 5, 0),
      todayPrayers: fakeDay(),
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: _texts(),
    );

    expect(plan.map((r) => r.id).toSet(), {1, 2, 3});
  });

  test('scheduleReminders carries the persisted wird settings into the plan',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = ReminderSettings(db);
    final city =
        CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    final prayer = FakePrayerTimeService()..todayResult = fakeDay();
    final scheduler = _CapturingScheduler();

    await city.select(cairoCity);
    await db.into(db.settingsTable).insert(SettingsTableCompanion.insert(
        key: wirdReminderEnabledKey, value: 'true'));
    await db.into(db.settingsTable).insert(SettingsTableCompanion.insert(
        key: wirdReminderTimeKey, value: '20:30'));

    await scheduleReminders(
      city: city,
      prayer: prayer,
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 10, 0),
    );

    final wird =
        scheduler.plans.single.singleWhere((r) => r.id == wirdReminderId);
    expect(wird.fireAt, DateTime(2026, 3, 15, 20, 30));
    expect(wird.payload, wirdReminderPayload);
  });

  test('without the wird keys scheduleReminders plans no wird reminder',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = ReminderSettings(db);
    final city =
        CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    final prayer = FakePrayerTimeService()..todayResult = fakeDay();
    final scheduler = _CapturingScheduler();

    await city.select(cairoCity);

    await scheduleReminders(
      city: city,
      prayer: prayer,
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 10, 0),
    );

    expect(
      scheduler.plans.single.where((r) => r.id == wirdReminderId),
      isEmpty,
    );
  });
}
