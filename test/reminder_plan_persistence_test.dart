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

    final first = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await first.init();
    await first.scheduleAll(plan);
    expect(store.snapshot, isNotNull);

    calls.clear();
    final second = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await second.init();
    await second.scheduleAll(plan);

    final methods = calls.map((call) => call.method).toList();
    expect(methods, isNot(contains('cancel')));
    expect(methods, isNot(contains('zonedSchedule')),
        reason: 'the background isolate must not rewrite the same alarms');
  });

  test('a reboot re-arms an unchanged plan; the OS lost its alarms', () async {
    final store = _MemoryStore();
    final plan = [_reminder(id: 1, title: 'Fajr', payload: 'prayer')];

    final first = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await first.init();
    await first.scheduleAll(plan);
    expect(store.snapshot?.bootId, 'boot-A');

    // A new process on the next boot: the plan is byte-identical, but the OS
    // dropped every alarm at reboot.
    calls.clear();
    final second = NotificationsBinding(store: store, bootId: () => 'boot-B');
    await second.init();
    await second.scheduleAll(plan);

    final methods = calls.map((call) => call.method).toList();
    expect(methods, contains('cancel'));
    expect(methods, contains('zonedSchedule'),
        reason: 'the boot path must re-arm a plan from a previous boot');
    expect(store.snapshot?.bootId, 'boot-B');
  });

  test('a null current boot id falls back to re-applying', () async {
    final store = _MemoryStore();
    final plan = [_reminder(id: 1, title: 'Fajr', payload: 'prayer')];

    final first = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await first.init();
    await first.scheduleAll(plan);
    expect(store.snapshot?.bootId, 'boot-A');

    // A platform where the kernel file cannot be read: a null stamp must
    // never suppress the apply; the same ids are cancelled and written once.
    calls.clear();
    final second = NotificationsBinding(store: store, bootId: () => null);
    await second.init();
    await second.scheduleAll(plan);

    final zoned =
        calls.where((call) => call.method == 'zonedSchedule').toList();
    expect(zoned, hasLength(1));
    final args = zoned.single.arguments as Map<Object?, Object?>;
    expect(args['id'], 1);
  });

  test('a snapshot without a boot id is not trusted', () async {
    final store = _MemoryStore()
      ..snapshot = const ReminderPlanSnapshot(
        fingerprint: 'legacy',
        exact: true,
      );
    final binding = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await binding.init();
    await binding.scheduleAll([
      _reminder(id: 1, title: 'Fajr', payload: 'prayer'),
    ]);

    expect(
      calls.map((call) => call.method),
      contains('zonedSchedule'),
      reason: 'an old app version stored no boot id; scheduling once is the '
          'only safe reading',
    );
  });

  test('a changed plan still replaces the OS alarms', () async {
    final store = _MemoryStore();
    final first = NotificationsBinding(store: store, bootId: () => 'boot-A');
    await first.init();
    await first.scheduleAll([_reminder(id: 1, title: 'old')]);

    calls.clear();
    final second = NotificationsBinding(store: store, bootId: () => 'boot-A');
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
