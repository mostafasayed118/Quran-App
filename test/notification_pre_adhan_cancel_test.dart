import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show azkarReminderId, prayerReminderId, preAdhanReminderId, wirdReminderId;

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return true;
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

  test('a removed pre-adhan id is cleared on the next plan', () async {
    final binding = NotificationsBinding();
    await binding.init();

    await binding.scheduleAll([
      _reminder(id: prayerReminderId, title: 'Fajr'),
      _reminder(id: azkarReminderId, title: 'Azkar'),
      _reminder(id: preAdhanReminderId, title: 'Soon'),
    ]);
    expect(
      _cancelIds(calls),
      unorderedEquals([prayerReminderId, azkarReminderId, wirdReminderId]),
    );

    calls.clear();
    await binding.scheduleAll([
      _reminder(id: prayerReminderId, title: 'Fajr'),
      _reminder(id: azkarReminderId, title: 'Azkar'),
    ]);

    expect(
      _cancelIds(calls),
      unorderedEquals([
        prayerReminderId,
        azkarReminderId,
        wirdReminderId,
        preAdhanReminderId,
      ]),
    );
  });

  test('a pre-adhan cancellation requested before init is queued', () async {
    final binding = NotificationsBinding();
    await binding.cancelPreAdhan();
    calls.clear();

    await binding.init();

    expect(_cancelIds(calls), [preAdhanReminderId]);
  });

  test('cancelPreAdhan clears id 4 directly after a restart', () async {
    final binding = NotificationsBinding();
    await binding.init();
    calls.clear();

    await binding.cancelPreAdhan();

    expect(_cancelIds(calls), [preAdhanReminderId]);
  });
}

ScheduledReminder _reminder({
  required int id,
  String title = 'Reminder',
}) =>
    ScheduledReminder(
      id: id,
      fireAt: DateTime.utc(2030, 1, 1, id),
      title: title,
    );

List<int> _cancelIds(List<MethodCall> calls) =>
    calls.where((call) => call.method == 'cancel').map((call) {
      final arguments = call.arguments;
      if (arguments is int) return arguments;
      return (arguments as Map<Object?, Object?>)['id'] as int;
    }).toList();
