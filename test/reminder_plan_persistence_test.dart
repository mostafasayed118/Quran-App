import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_plan_store.dart';

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

class _MemoryStore implements ReminderPlanStore {
  ReminderPlanSnapshot? snapshot;

  @override
  Future<ReminderPlanSnapshot?> read() async => snapshot;

  @override
  Future<void> write(ReminderPlanSnapshot value) async => snapshot = value;

  @override
  Future<void> clear() async => snapshot = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late bool exact;

  setUp(() {
    calls = <MethodCall>[];
    exact = true;
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
          return exact;
        case 'areNotificationsEnabled':
          return false;
        case 'requestNotificationsPermission':
        case 'requestExactAlarmsPermission':
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

  test('a new binding skips a plan the previous process applied', () async {
    final store = _MemoryStore();
    final plan = [_reminder(id: 1, title: 'Fajr', payload: 'prayer')];

    final first = NotificationsBinding(store: store);
    await first.init();
    await first.scheduleAll(plan);
    expect(store.snapshot, isNotNull);

    calls.clear();
    final second = NotificationsBinding(store: store);
    await second.init();
    await second.scheduleAll(plan);

    final methods = calls.map((call) => call.method).toList();
    expect(methods, isNot(contains('cancel')));
    expect(methods, isNot(contains('zonedSchedule')),
        reason: 'the background isolate must not rewrite the same alarms');
  });

  test('a changed plan still replaces the OS alarms', () async {
    final store = _MemoryStore();
    final first = NotificationsBinding(store: store);
    await first.init();
    await first.scheduleAll([_reminder(id: 1, title: 'old')]);

    calls.clear();
    final second = NotificationsBinding(store: store);
    await second.init();
    await second.scheduleAll([_reminder(id: 1, title: 'new')]);

    final methods = calls.map((call) => call.method).toList();
    expect(methods, contains('cancel'));
    expect(methods, contains('zonedSchedule'));
  });
}

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
