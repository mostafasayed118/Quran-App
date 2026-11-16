import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/platform/reminder_alarm_probe.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_plan_store.dart';

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

class _Probe implements ReminderAlarmProbe {
  _Probe({this.exitReason});

  bool exists = true;
  bool throws = false;
  String? exitReason;
  int probes = 0;

  @override
  Future<bool> alarmExists(int notificationId) async {
    probes++;
    if (throws) throw StateError('probe failed');
    return exists;
  }

  @override
  Future<String?> lastExitReason() async => exitReason;
}

class _MemoryStore implements ReminderPlanStore {
  ReminderPlanSnapshot? snapshot;

  @override
  Future<ReminderPlanSnapshot?> read() async => snapshot;

  @override
  Future<void> write(ReminderPlanSnapshot next) async => snapshot = next;

  @override
  Future<void> clear() async => snapshot = null;
}

ScheduledReminder _reminder(int id) => ScheduledReminder(
      id: id,
      fireAt: DateTime.now().add(const Duration(hours: 1)),
      title: 'reminder $id',
      payload: 'prayer',
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
        case 'areNotificationsEnabled':
          return true;
        case 'pendingNotificationRequests':
          return <Object?>[];
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

  int zonedCalls() => calls.where((c) => c.method == 'zonedSchedule').length;

  Future<NotificationsBinding> build({
    required _Probe probe,
    required _MemoryStore store,
  }) async {
    final binding = NotificationsBinding(
      plugin: FlutterLocalNotificationsPlugin(),
      store: store,
      bootId: () => 'boot-A',
      alarmProbe: probe,
    );
    await binding.init();
    return binding;
  }

  test('a matching plan whose alarms the OS lost is re-armed', () async {
    final plan = [_reminder(1000), _reminder(1003)];
    final probe = _Probe();
    final store = _MemoryStore();
    final binding = await build(probe: probe, store: store);

    await binding.scheduleAll(plan);
    final first = zonedCalls();
    expect(first, 2);

    // Force stop cleared the alarms; the plan and the fingerprint did not move.
    probe.exists = false;
    await binding.scheduleAll(plan);

    expect(zonedCalls(), first + 2,
        reason: 'the binding must not trust a fingerprint the OS contradicts');
  });

  test('a normal resume with the alarms alive schedules nothing', () async {
    final plan = [_reminder(1000), _reminder(1003)];
    final probe = _Probe();
    final store = _MemoryStore();
    final binding = await build(probe: probe, store: store);
    await binding.scheduleAll(plan);
    final first = zonedCalls();

    await binding.scheduleAll(plan);

    expect(zonedCalls(), first, reason: 'no rearm on a healthy resume');
  });

  test('a failing probe counts as missing and re-arms once', () async {
    final plan = [_reminder(1000), _reminder(1003)];
    final probe = _Probe();
    final store = _MemoryStore();
    final binding = await build(probe: probe, store: store);
    await binding.scheduleAll(plan);
    final first = zonedCalls();

    probe.throws = true;
    await binding.scheduleAll(plan);
    expect(zonedCalls(), first + 2);

    probe.throws = false;
    await binding.scheduleAll(plan);
    expect(zonedCalls(), first + 2,
        reason: 'the rearm itself is idempotent and does not loop');
  });

  test('the exit-reason flag bypasses a matching snapshot exactly once',
      () async {
    final plan = [_reminder(1000), _reminder(1003)];
    final store = _MemoryStore();

    final warm = await build(probe: _Probe(), store: store);
    await warm.scheduleAll(plan);
    final baseline = zonedCalls();
    expect(baseline, 2);

    final forced = await build(probe: _Probe(exitReason: '10'), store: store);
    await forced.scheduleAll(plan);
    expect(zonedCalls(), baseline + 2,
        reason: 'a force-stop exit reason must not be defeated by the '
            'snapshot it left behind');

    final healthy = await build(probe: _Probe(), store: store);
    await healthy.scheduleAll(plan);
    expect(zonedCalls(), baseline + 2,
        reason: 'the flag is consumed by the successful apply');
  });
}
