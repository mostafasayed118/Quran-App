import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';

ScheduledReminder prayerReminder({String? adhanId}) => ScheduledReminder(
      id: prayerReminderId,
      fireAt: DateTime.utc(2026, 3, 15, 4, 45),
      title: 'prayer:fajr',
      payload: prayerReminderPayload,
      adhanId: adhanId,
    );

void main() {
  test('an unchanged plan keeps the same fingerprint', () {
    expect(
      NotificationsBinding.planFingerprint([prayerReminder(adhanId: 'khushu')]),
      NotificationsBinding.planFingerprint([prayerReminder(adhanId: 'khushu')]),
    );
  });

  test('changing only the adhan changes the fingerprint', () {
    // Without this the scheduler treats "same alarm, different sound" as a
    // no-op and the user keeps hearing the reciter they just replaced until a
    // restart happens to change something else.
    expect(
      NotificationsBinding.planFingerprint([prayerReminder(adhanId: 'khushu')]),
      isNot(NotificationsBinding.planFingerprint(
        [prayerReminder(adhanId: 'omar_hisham')],
      )),
    );
  });

  test('dropping the adhan changes the fingerprint', () {
    expect(
      NotificationsBinding.planFingerprint([prayerReminder(adhanId: 'khushu')]),
      isNot(NotificationsBinding.planFingerprint([prayerReminder()])),
    );
  });

  test('the fingerprint is order-independent', () {
    final azkar = ScheduledReminder(
      id: azkarReminderId,
      fireAt: DateTime.utc(2026, 3, 15, 4, 30),
      title: 'azkar',
    );
    final a = NotificationsBinding.planFingerprint(
      [prayerReminder(adhanId: 'khushu'), azkar],
    );
    final b = NotificationsBinding.planFingerprint(
      [azkar, prayerReminder(adhanId: 'khushu')],
    );
    expect(a, b);
  });
}
