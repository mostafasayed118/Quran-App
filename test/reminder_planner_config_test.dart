import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 1, hour, minute);

List<PrayerChoice> _day() => [
      PrayerChoice(PrayerName.fajr, _at(5)),
      PrayerChoice(PrayerName.sunrise, _at(6)),
      PrayerChoice(PrayerName.dhuhr, _at(12)),
      PrayerChoice(PrayerName.asr, _at(15)),
      PrayerChoice(PrayerName.maghrib, _at(17, 30)),
      PrayerChoice(PrayerName.isha, _at(19)),
    ];

ReminderTexts _texts() => ReminderTexts(
      prayerTitle: (prayer) => 'prayer ${prayer.name}',
      prayerSoonTitle: (prayer, minutes) => 'soon ${prayer.name} $minutes',
      azkarTitle: 'azkar',
      wirdTitle: 'wird',
    );

void main() {
  test('defaults keep the frozen one-prayer plan', () {
    final plan = planReminders(
      now: _at(4),
      todayPrayers: _day(),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan.map((r) => r.id), [prayerReminderId]);
    expect(plan.single.fireAt, _at(5));
    expect(plan.single.payload, prayerReminderPayload);
  });

  test('disabled prayers are skipped when choosing the reminder', () {
    final plan = planReminders(
      now: _at(4),
      todayPrayers: _day(),
      enabledPrayers: const {PrayerName.dhuhr, PrayerName.isha},
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan.single.fireAt, _at(12));
  });

  test('disabling every prayer drops the prayer reminder entirely', () {
    final plan = planReminders(
      now: _at(4),
      todayPrayers: _day(),
      enabledPrayers: const <PrayerName>{},
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: _texts(),
    );

    expect(plan.map((r) => r.id), isNot(contains(prayerReminderId)));
    expect(plan.map((r) => r.id), contains(azkarReminderId));
  });

  test('a pre-adhan reminder is scheduled ahead of the chosen prayer', () {
    final plan = planReminders(
      now: _at(4),
      todayPrayers: _day(),
      preAdhanMinutes: 15,
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    final soon = plan.singleWhere((r) => r.id == preAdhanReminderId);
    expect(soon.fireAt, _at(4, 45));
    expect(soon.title, 'soon fajr 15');
    expect(soon.payload, prayerReminderPayload);
  });

  test('a pre-adhan time already passed is skipped', () {
    final plan = planReminders(
      now: _at(4, 50),
      todayPrayers: _day(),
      preAdhanMinutes: 15,
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan.map((r) => r.id), [prayerReminderId]);
  });

  test('the next tomorrow prayer is used when no enabled prayer is ahead', () {
    final plan = planReminders(
      now: _at(20),
      todayPrayers: _day(),
      nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 11, 2, 5)),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan.single.fireAt, DateTime(2026, 11, 2, 5));
  });

  test('a disabled tomorrow prayer suppresses the reminder', () {
    final plan = planReminders(
      now: _at(20),
      todayPrayers: _day(),
      nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 11, 2, 5)),
      enabledPrayers: const {PrayerName.dhuhr},
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan, isEmpty);
  });
}
