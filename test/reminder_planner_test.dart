import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

List<PrayerChoice> fakeDay() => [
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
      PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
      PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
      PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
      PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
      PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
    ];

void main() {
  List<PrayerName> textCalls() => <PrayerName>[];

  ReminderTexts texts(List<PrayerName> calls) => ReminderTexts(
        prayerTitle: (name) {
          calls.add(name);
          return 'حان موعد صلاة ${name.name}';
        },
        azkarTitle: 'أذكار الصباح',
        azkarBody: 'أذكار الصباح',
      );

  test('next prayer is picked strictly ahead; sunrise is skipped', () {
    final calls = textCalls();
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: fakeDay(),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: texts(calls),
    );

    expect(plan, hasLength(1));
    expect(plan.single.id, prayerReminderId);
    expect(plan.single.fireAt, DateTime(2026, 3, 15, 12, 5));
    expect(plan.single.title, 'حان موعد صلاة dhuhr');
    expect(calls, [PrayerName.dhuhr]);
  });

  test('a prayer exactly at now is not ahead; the following one wins', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 12, 5),
      todayPrayers: fakeDay(),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: texts(textCalls()),
    );

    expect(plan.single.fireAt, DateTime(2026, 3, 15, 15, 35));
  });

  test('azkar is scheduled today while its time is still ahead', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 5, 0),
      todayPrayers: <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: texts(textCalls()),
    );

    expect(plan, hasLength(1));
    expect(plan.single.id, azkarReminderId);
    expect(plan.single.fireAt, DateTime(2026, 3, 15, 6, 30));
    expect(plan.single.title, 'أذكار الصباح');
    expect(plan.single.body, 'أذكار الصباح');
  });

  test('azkar rolls to tomorrow once its time has passed', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 7, 0),
      todayPrayers: <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: texts(textCalls()),
    );

    expect(plan.single.fireAt, DateTime(2026, 3, 16, 6, 30));
  });

  test('disabled azkar and no prayer ahead → empty plan', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 23, 0),
      todayPrayers: fakeDay(),
      azkarEnabled: false,
      azkarTimeHm: '06:30',
      texts: texts(textCalls()),
    );

    expect(plan, isEmpty);
  });

  test('malformed azkar time falls back to the 06:30 default', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 7, 0),
      todayPrayers: <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: '25:99',
      texts: texts(textCalls()),
    );

    expect(plan.single.fireAt, DateTime(2026, 3, 16, 6, 30));
  });

  test('null azkar time falls back to the 06:30 default too', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 5, 0),
      todayPrayers: <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: null,
      texts: texts(textCalls()),
    );

    expect(plan.single.fireAt, DateTime(2026, 3, 15, 6, 30));
  });

  test('fire times are normalized (dateOnly + time) and ids are unique', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 5, 0, 45, 123),
      todayPrayers: fakeDay(),
      azkarEnabled: true,
      azkarTimeHm: '6:30',
      texts: texts(textCalls()),
    );

    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
    final azkar = plan.singleWhere((r) => r.id == azkarReminderId);
    expect(azkar.fireAt, DateTime(2026, 3, 15, 6, 30));
    final prayer = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.fireAt, DateTime(2026, 3, 15, 12, 5));
  });

  test('duplicate prayer entries in the day are deduped to one reminder', () {
    final doubled = [...fakeDay(), ...fakeDay()];
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 10, 0),
      todayPrayers: doubled,
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: texts(textCalls()),
    );

    expect(plan, hasLength(1));
    expect(plan.single.id, prayerReminderId);
  });
}
