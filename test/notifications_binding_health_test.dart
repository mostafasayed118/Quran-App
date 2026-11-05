import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';

/// The channel the plugin's Android implementation talks to.
const MethodChannel _channel =
    MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool failInitialize;
  late bool failSchedule;
  late int scheduleCalls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // The plugin's `resolvePlatformSpecificImplementation` only returns the
    // Android implementation when it is the registered platform instance.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    failInitialize = false;
    failSchedule = false;
    scheduleCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'initialize':
          if (failInitialize) {
            throw PlatformException(code: 'init-failed');
          }
          return true;
        case 'zonedSchedule':
          scheduleCalls += 1;
          if (failSchedule) {
            throw PlatformException(code: 'schedule-failed');
          }
          return null;
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

  ScheduledReminder reminder() => ScheduledReminder(
        id: 9001,
        fireAt: DateTime.now().add(const Duration(hours: 1)),
        title: 'test reminder',
      );

  test('a failed init reports the health flag', () async {
    failInitialize = true;
    final binding = NotificationsBinding();
    addTearDown(binding.dispose);

    await binding.init();

    expect(binding.lastApplyFailed, isTrue);
  });

  test('a failed apply flips true and a later success clears it', () async {
    final binding = NotificationsBinding();
    addTearDown(binding.dispose);
    await binding.init();
    expect(binding.lastApplyFailed, isFalse);

    failSchedule = true;
    await binding.scheduleAll([reminder()]);
    expect(binding.lastApplyFailed, isTrue);
    expect(scheduleCalls, 1);

    failSchedule = false;
    await binding.scheduleAll([reminder()]);
    expect(binding.lastApplyFailed, isFalse);
    expect(scheduleCalls, 2);
  });
}
