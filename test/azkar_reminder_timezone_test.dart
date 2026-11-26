import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// M1 (audit round 2): the azkar/wird reminders must be computed on the city's
/// wall clock, like the prayer alarms — not on the device's local clock.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  ReminderTexts texts() => ReminderTexts(
    prayerTitle: (name) => 'prayer ${name.name}',
    azkarTitle: 'azkar',
    wirdTitle: 'wird',
  );

  test('azkar fires at the city wall clock, not the device clock', () {
    final tokyo = tz.getLocation('Asia/Tokyo');
    final now = tz.TZDateTime(tokyo, 2026, 3, 15, 5, 0);

    final plan = planReminders(
      now: now,
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      texts: texts(),
    );

    final azkar = plan.singleWhere((r) => r.id == azkarReminderId);
    expect(azkar.fireAt, tz.TZDateTime(tokyo, 2026, 3, 15, 6, 30));
  });

  test('wird rolls to the next city day on the city wall clock', () {
    final tokyo = tz.getLocation('Asia/Tokyo');
    final now = tz.TZDateTime(tokyo, 2026, 3, 15, 21, 0);

    final plan = planReminders(
      now: now,
      todayPrayers: const <PrayerChoice>[],
      azkarEnabled: false,
      azkarTimeHm: null,
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: texts(),
    );

    final wird = plan.singleWhere((r) => r.id == wirdReminderId);
    expect(wird.fireAt, tz.TZDateTime(tokyo, 2026, 3, 16, 20, 0));
  });
}
