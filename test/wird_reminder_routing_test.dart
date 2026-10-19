import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/main.dart' show reminderRouteFor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a wird payload routes to the worship tracker', () {
    expect(reminderRouteFor(wirdReminderPayload), '/worship');
  });

  test('the wird kind keeps a distinct id and payload tag', () {
    expect(wirdReminderId, 3);
    expect(wirdReminderPayload, 'wird');
    expect(
      {prayerReminderId, azkarReminderId, wirdReminderId},
      hasLength(3),
    );
    expect(
      {prayerReminderPayload, azkarReminderPayload, wirdReminderPayload},
      hasLength(3),
    );
  });

  test('a wird-payloaded tap fires the payload callback, not the plain one',
      () async {
    final binding = NotificationsBinding();
    final plain = <String>[];
    final payloads = <String>[];
    await binding.init(
      onTap: () => plain.add('default'),
      onTapPayload: payloads.add,
    );

    binding.onNotificationTap(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: wirdReminderPayload,
    ));

    expect(payloads, ['wird']);
    expect(plain, isEmpty);
  });
}
