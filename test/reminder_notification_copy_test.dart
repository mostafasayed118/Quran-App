import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart'
    show FakePrayerTimeService, cairoCity, fakeDay;

class CapturingScheduler implements ReminderSchedulerPort {
  final plans = <List<ScheduledReminder>>[];

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    plans.add(reminders);
  }
}

void main() {
  test('planner keeps the shade title-only: no duplicated body copy', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: fakeDay(),
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: ReminderTexts(
        prayerTitle: (name) => 'حان موعد صلاة ${name.name}',
        azkarTitle: 'أذكار الصباح',
      ),
    );

    final prayer = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.body, isNull);
    expect(prayer.title, 'حان موعد صلاة dhuhr');
    final azkar = plan.singleWhere((r) => r.id == azkarReminderId);
    expect(azkar.body, isNull);
    expect(azkar.title, 'أذكار الصباح');
  });

  test('planner still passes a provided azkar body through (contract held)',
      () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 5, 0),
      todayPrayers: <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: ReminderTexts(
        prayerTitle: (name) => 'x',
        azkarTitle: 'أذكار الصباح',
        azkarBody: 'جسم مخصص',
      ),
    );

    expect(
      plan.singleWhere((r) => r.id == azkarReminderId).body,
      'جسم مخصص',
    );
  });

  test('the schedule composition ships title-only reminders with payloads',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = ReminderSettings(db);
    final city =
        CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    final prayer = FakePrayerTimeService()..todayResult = fakeDay();
    final scheduler = CapturingScheduler();

    await city.select(cairoCity);
    await settings.setAzkarEnabled(true);
    await settings.setAzkarTime('09:00');

    await scheduleReminders(
      city: city,
      prayer: prayer,
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 10, 0),
    );

    final plan = scheduler.plans.single;
    final prayerReminder = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(prayerReminder.body, isNull);
    expect(prayerReminder.payload, prayerReminderPayload);

    final azkar = plan.singleWhere((r) => r.id == azkarReminderId);
    expect(azkar.body, isNull);
    expect(azkar.title, 'أذكار الصباح');
    expect(azkar.payload, azkarReminderPayload);
  });

  test('the shared channel description speaks for prayer and azkar', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(ar.reminderChannelDescription, 'تذكيرات الصلاة والأذكار');
    expect(en.reminderChannelDescription, 'Prayer and azkar reminders');
  });
}
