import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late bool exact;
  late bool notificationsEnabled;
  String? throwOn;
  int? throwOnId;

  setUp(() {
    calls = <MethodCall>[];
    exact = true;
    notificationsEnabled = false;
    throwOn = null;
    throwOnId = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (throwOn != null && call.method == throwOn) {
        throw PlatformException(code: 'boom');
      }
      if (throwOnId != null && call.method == 'zonedSchedule') {
        final args = call.arguments as Map<Object?, Object?>;
        if (args['id'] == throwOnId) {
          throw PlatformException(code: 'boom');
        }
      }
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return exact;
        case 'areNotificationsEnabled':
          return notificationsEnabled;
        case 'requestNotificationsPermission':
        case 'requestExactAlarmsPermission':
          return true;
        case 'getNotificationAppLaunchDetails':
          return <String, Object?>{
            'notificationLaunchedApp': true,
            'notificationResponse': <String, Object?>{
              'notificationId': 1,
              'actionId': null,
              'input': null,
              'notificationResponseType': 0,
              'payload': 'prayer',
            },
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('a failed plan does not block re-applying the previous plan', () async {
    final binding = NotificationsBinding();
    await binding.init();

    final planA = [_reminder(id: 1, title: 'Azkar')];
    await binding.scheduleAll(planA);
    expect(_zonedForId(calls, 1), 1);

    throwOn = 'zonedSchedule';
    await binding.scheduleAll([_reminder(id: 2, title: 'Wird')]);
    throwOn = null;

    await binding.scheduleAll(planA);
    final afterRetry = _zonedForId(calls, 1);
    expect(afterRetry, greaterThanOrEqualTo(2),
        reason: 'cancelAll cleared the alarms, so plan A must be re-scheduled');
  });

  test('one rejected alarm does not skip the later chunks', () async {
    final binding = NotificationsBinding();
    await binding.init();
    final plan = [for (var id = 1; id <= 17; id++) _reminder(id: id)];

    throwOnId = 9;
    await binding.scheduleAll(plan);

    expect(_zonedForId(calls, 9), 1,
        reason: 'the failing alarm is attempted and rejected');
    expect(_zonedForId(calls, 17), 1,
        reason: 'the alarm after the failing chunk must still be scheduled');
  });
}

int _zonedForId(List<MethodCall> calls, int id) => calls
    .where((call) =>
        call.method == 'zonedSchedule' &&
        (call.arguments as Map<Object?, Object?>)['id'] == id)
    .length;

ScheduledReminder _reminder({
  required int id,
  String title = 'Reminder',
  String? body,
  String? payload,
  DateTime? fireAt,
}) =>
    ScheduledReminder(
      id: id,
      fireAt: fireAt ?? DateTime.utc(2030, 1, 1, id),
      title: title,
      body: body,
      payload: payload,
    );
