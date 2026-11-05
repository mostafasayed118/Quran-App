import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_diagnostics_channel.dart';

const MethodChannel _channel =
    MethodChannel('quran_yahdi/reminder_diagnostics');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('diagnoseReminders', () {
    test('a healthy device reports nothing', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: true,
          exactAlarmsAllowed: true,
          batteryOptimizationIgnored: true,
        ),
        isEmpty,
      );
    });

    test('notifications off is reported', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: false,
          exactAlarmsAllowed: true,
          batteryOptimizationIgnored: true,
        ),
        [ReminderIssue.notificationsOff],
      );
    });

    test('exact alarms off is reported', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: true,
          exactAlarmsAllowed: false,
          batteryOptimizationIgnored: true,
        ),
        [ReminderIssue.exactAlarmsOff],
      );
    });

    test('a battery restriction is reported', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: true,
          exactAlarmsAllowed: true,
          batteryOptimizationIgnored: false,
        ),
        [ReminderIssue.batteryRestricted],
      );
    });

    test('a failed plan write is reported even when every permission is on',
        () {
      expect(
        diagnoseReminders(
          notificationsEnabled: true,
          exactAlarmsAllowed: true,
          batteryOptimizationIgnored: true,
          scheduleFailed: true,
        ),
        [ReminderIssue.scheduleFailed],
      );
    });

    test('an unreadable battery state is not an issue', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: true,
          exactAlarmsAllowed: true,
          batteryOptimizationIgnored: null,
        ),
        isEmpty,
      );
    });

    test('several issues keep the display order', () {
      expect(
        diagnoseReminders(
          notificationsEnabled: false,
          exactAlarmsAllowed: false,
          batteryOptimizationIgnored: false,
        ),
        [
          ReminderIssue.notificationsOff,
          ReminderIssue.exactAlarmsOff,
          ReminderIssue.batteryRestricted,
        ],
      );
    });
  });

  group('ReminderDiagnosticsChannel', () {
    late List<MethodCall> calls;
    late Set<String> throwOn;
    late bool? batteryAnswer;

    setUp(() {
      calls = <MethodCall>[];
      throwOn = <String>{};
      batteryAnswer = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        calls.add(call);
        if (throwOn.contains(call.method)) {
          throw PlatformException(code: 'boom', message: call.method);
        }
        switch (call.method) {
          case 'notificationsEnabled':
            return true;
          case 'exactAlarmsAllowed':
            return false;
          case 'batteryOptimizationIgnored':
            return batteryAnswer;
          case 'openBatteryOptimizationSettings':
          case 'openExactAlarmSettings':
            return true;
          default:
            throw PlatformException(code: 'unexpected', message: call.method);
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('the three reads use the Kotlin method names', () async {
      const diagnostics = ReminderDiagnosticsChannel();

      await diagnostics.notificationsEnabled();
      await diagnostics.exactAlarmsAllowed();
      await diagnostics.batteryOptimizationIgnored();

      expect(
        calls.map((call) => call.method),
        [
          'notificationsEnabled',
          'exactAlarmsAllowed',
          'batteryOptimizationIgnored',
        ],
      );
    });

    test('the reads map the platform results', () async {
      const diagnostics = ReminderDiagnosticsChannel();
      batteryAnswer = false;

      expect(await diagnostics.notificationsEnabled(), isTrue);
      expect(await diagnostics.exactAlarmsAllowed(), isFalse);
      expect(await diagnostics.batteryOptimizationIgnored(), isFalse);
    });

    test('a platform exception reads as unknown, never as a thrown error',
        () async {
      const diagnostics = ReminderDiagnosticsChannel();
      throwOn = {
        'notificationsEnabled',
        'exactAlarmsAllowed',
        'batteryOptimizationIgnored'
      };

      // A failed permission read reports "no issue": fabricating a problem
      // the user cannot see is worse than staying silent about it.
      expect(await diagnostics.notificationsEnabled(), isTrue);
      expect(await diagnostics.exactAlarmsAllowed(), isTrue);
      // A failed battery read is "cannot report" — the instruction row.
      expect(await diagnostics.batteryOptimizationIgnored(), isNull);
    });

    test('a missing platform implementation reads as unknown', () async {
      const diagnostics = ReminderDiagnosticsChannel();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);

      expect(await diagnostics.notificationsEnabled(), isTrue);
      expect(await diagnostics.batteryOptimizationIgnored(), isNull);
    });

    test('the two open actions report whether a screen was shown', () async {
      const diagnostics = ReminderDiagnosticsChannel();

      expect(await diagnostics.openBatteryOptimizationSettings(), isTrue);
      expect(await diagnostics.openExactAlarmSettings(), isTrue);

      throwOn = {'openBatteryOptimizationSettings', 'openExactAlarmSettings'};
      expect(await diagnostics.openBatteryOptimizationSettings(), isFalse);
      expect(await diagnostics.openExactAlarmSettings(), isFalse);
    });
  });
}
