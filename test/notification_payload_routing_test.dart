import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/main.dart' show reminderRouteFor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reminderRouteFor (pure payload to route map)', () {
    test('a prayer payload routes to the prayer-times screen', () {
      expect(reminderRouteFor(prayerReminderPayload), '/prayer-times');
    });

    test('an azkar payload routes to the azkar screen', () {
      expect(reminderRouteFor(azkarReminderPayload), '/azkar');
    });

    test('unknown or absent payloads have no route (caller falls back)', () {
      expect(reminderRouteFor('unknown'), isNull);
      expect(reminderRouteFor(''), isNull);
      expect(reminderRouteFor(null), isNull);
    });
  });

  group('NotificationsBinding tap routing', () {
    test('a payloaded tap fires the payload callback, not the plain one',
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
        payload: prayerReminderPayload,
      ));

      expect(payloads, ['prayer']);
      expect(plain, isEmpty);
    });

    test('a payloadless tap keeps the default-launch callback', () async {
      final binding = NotificationsBinding();
      final plain = <String>[];
      final payloads = <String>[];
      await binding.init(
        onTap: () => plain.add('default'),
        onTapPayload: payloads.add,
      );

      binding.onNotificationTap(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ));

      expect(plain, ['default']);
      expect(payloads, isEmpty);
    });

    test('a payloaded tap without a payload callback falls back to plain',
        () async {
      final binding = NotificationsBinding();
      final plain = <String>[];
      await binding.init(onTap: () => plain.add('default'));

      binding.onNotificationTap(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: azkarReminderPayload,
      ));

      expect(plain, ['default']);
    });
  });

  test('launchPayload is null when the plugin is unavailable (never throws)',
      () async {
    final binding = NotificationsBinding();

    expect(await binding.launchPayload(), isNull);
  });
}
