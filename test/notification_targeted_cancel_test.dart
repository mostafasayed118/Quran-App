import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show azkarReminderId, prayerReminderId, wirdReminderId;

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late bool exact;
  String? throwOn;

  setUp(() {
    calls = <MethodCall>[];
    exact = true;
    throwOn = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (throwOn != null && call.method == throwOn) {
        throw PlatformException(code: 'boom');
      }
      switch (call.method) {
        case 'initialize':
          return true;
        case 'canScheduleExactNotifications':
          return exact;
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

  test('applying a plan cancels only the reminder ids', () async {
    final binding = NotificationsBinding();
    await binding.init();

    await binding.scheduleAll([_reminder(id: prayerReminderId, title: 'Fajr')]);

    expect(
      _methods(calls).where((method) => method == 'cancelAll'),
      isEmpty,
      reason: 'cancelAll wipes the playback notification posted by '
          'just_audio_background, not just the reminder alarms',
    );
    expect(
      _cancelIds(calls),
      unorderedEquals([prayerReminderId, azkarReminderId, wirdReminderId]),
    );
  });

  test('the scheduled plan keeps its count and ids', () async {
    final binding = NotificationsBinding();
    await binding.init();

    await binding.scheduleAll([
      _reminder(id: prayerReminderId, title: 'Fajr'),
      _reminder(id: wirdReminderId, title: 'Wird'),
    ]);

    expect(_zonedIds(calls), [prayerReminderId, wirdReminderId]);
  });

  test('a plan re-applied after another plan is scheduled again', () async {
    final binding = NotificationsBinding();
    await binding.init();
    final planA = [_reminder(id: prayerReminderId, title: 'Fajr')];
    final planB = [_reminder(id: azkarReminderId, title: 'Azkar')];

    await binding.scheduleAll(planA);
    // The failed apply is what pins the fingerprint invalidation: plan A must
    // be re-scheduled even though a later plan was requested meanwhile.
    throwOn = 'zonedSchedule';
    await binding.scheduleAll(planB);
    throwOn = null;
    await binding.scheduleAll(planA);

    expect(
      _zonedIds(calls),
      [prayerReminderId, azkarReminderId, prayerReminderId],
    );
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

List<String> _methods(List<MethodCall> calls) =>
    calls.map((call) => call.method).toList();

List<int> _zonedIds(List<MethodCall> calls) => calls
    .where((call) => call.method == 'zonedSchedule')
    .map((call) => _arguments(call)['id'] as int)
    .toList();

/// The ids of the recorded `cancel` calls: the Android platform sends a map,
/// the base method-channel platform sends the bare id.
List<int> _cancelIds(List<MethodCall> calls) =>
    calls.where((call) => call.method == 'cancel').map((call) {
      final arguments = call.arguments;
      if (arguments is int) return arguments;
      return (arguments as Map<Object?, Object?>)['id'] as int;
    }).toList();

Map<Object?, Object?> _arguments(MethodCall call) =>
    call.arguments as Map<Object?, Object?>;
