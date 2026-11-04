import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show reminderAlarmIds;

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late bool exact;
  late bool notificationsEnabled;
  String? throwOn;

  setUp(() {
    calls = <MethodCall>[];
    exact = true;
    notificationsEnabled = false;
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

  test('a plan scheduled before init is queued and drained by init', () async {
    final binding = NotificationsBinding();
    await binding.scheduleAll([
      _reminder(id: 1, title: 'Fajr', payload: 'prayer'),
      _reminder(id: 3, title: 'Wird', payload: 'wird'),
    ]);

    expect(calls, isEmpty);

    await binding.init();

    final methods = _methods(calls);
    expect(methods.take(2).toList(),
        ['initialize', 'canScheduleExactNotifications']);
    expect(
      methods.sublist(2, methods.length - 2),
      everyElement('cancel'),
      reason: 'every planner id is cleared before the plan lands',
    );
    expect(methods.sublist(methods.length - 2),
        ['zonedSchedule', 'zonedSchedule']);
    expect(_zonedIds(calls), [1, 3]);
  });

  test('an identical plan re-sent does not touch the channel again', () async {
    final binding = NotificationsBinding();
    await binding.init();
    await binding.scheduleAll([_reminder(id: 1, title: 'Azkar')]);

    final before = calls.length;
    await binding.scheduleAll([_reminder(id: 1, title: 'Azkar')]);

    expect(
      _methods(calls.sublist(before)),
      ['canScheduleExactNotifications'],
      reason: 'the mode probe runs on every apply (the exact-alarm grant can '
          'change), but no alarm is cancelled or scheduled again',
    );
  });

  test('the plan fingerprint is order-insensitive', () async {
    final binding = NotificationsBinding();
    await binding.init();
    final first = _reminder(id: 1, title: 'Azkar');
    final second = _reminder(id: 2, title: 'Wird');
    await binding.scheduleAll([first, second]);

    final before = calls.length;
    await binding.scheduleAll([second, first]);

    expect(
      _methods(calls.sublist(before)),
      ['canScheduleExactNotifications'],
      reason: 'same plan in another order = same alarms, so no re-schedule',
    );
  });

  test('a title change re-registers the plan', () async {
    final binding = NotificationsBinding();
    await binding.init();
    await binding.scheduleAll([_reminder(id: 1, title: 'old title')]);

    final before = calls.length;
    await binding.scheduleAll([_reminder(id: 1, title: 'new title')]);

    final added = _methods(calls.sublist(before));
    expect(added,
        containsAllInOrder(['cancel', 'cancel', 'cancel', 'zonedSchedule']));
    expect(_zoned(calls.sublist(before)), hasLength(1));
  });

  test('a payload change re-registers the plan', () async {
    final binding = NotificationsBinding();
    await binding.init();
    await binding.scheduleAll([
      _reminder(id: 1, title: 'Azkar', payload: 'azkar'),
    ]);

    final before = calls.length;
    await binding.scheduleAll([
      _reminder(id: 1, title: 'Azkar', payload: 'prayer'),
    ]);

    final added = _methods(calls.sublist(before));
    expect(added,
        containsAllInOrder(['cancel', 'cancel', 'cancel', 'zonedSchedule']));
    expect(_zoned(calls.sublist(before)), hasLength(1));
  });

  test('exact alarms use exactAllowWhileIdle when the OS allows them',
      () async {
    exact = true;
    final binding = NotificationsBinding();
    await binding.init();
    await binding.scheduleAll([_reminder(id: 1), _reminder(id: 2)]);

    expect(_scheduleModes(calls), [
      'exactAllowWhileIdle',
      'exactAllowWhileIdle',
    ]);
  });

  test('inexact alarms use inexactAllowWhileIdle when exact is denied',
      () async {
    exact = false;
    final binding = NotificationsBinding();
    await binding.init();
    await binding.scheduleAll([_reminder(id: 1)]);

    expect(_scheduleModes(calls), ['inexactAllowWhileIdle']);
  });

  test('granting exact alarms upgrades an already-applied plan', () async {
    exact = false;
    final binding = NotificationsBinding();
    await binding.init();
    final plan = [_reminder(id: 1)];
    await binding.scheduleAll(plan);

    expect(_scheduleModes(calls), ['inexactAllowWhileIdle']);

    calls.clear();
    exact = true;
    await binding.scheduleAll(plan);

    expect(
      _scheduleModes(calls),
      ['exactAllowWhileIdle'],
      reason: 'the grant changes the schedule MODE, not the plan, so the '
          'fingerprint alone must not dedupe the re-apply away',
    );
  });

  test('a permission queued before init is applied before the plan', () async {
    final binding = NotificationsBinding();
    expect(await binding.ensurePermissions(), isTrue);
    await binding.scheduleAll([_reminder(id: 1)]);
    expect(calls, isEmpty);

    await binding.init();

    final methods = _methods(calls);
    expect(methods.first, 'initialize');
    expect(
        methods,
        containsAllInOrder([
          'requestNotificationsPermission',
          'requestExactAlarmsPermission',
          'cancel',
        ]));
    // Every planner id is cleared before the plan lands, and the plan lands.
    expect(methods.lastIndexOf('cancel'),
        lessThan(methods.indexOf('zonedSchedule')));
  });

  test('a failed init drops the queued plan and permission', () async {
    final binding = NotificationsBinding();
    expect(await binding.ensurePermissions(), isTrue);
    await binding.scheduleAll([_reminder(id: 1)]);
    throwOn = 'initialize';

    await binding.init();

    final afterInit = calls.length;
    await binding.scheduleAll([_reminder(id: 2)]);
    expect(await binding.ensurePermissions(), isFalse);

    expect(calls.length, afterInit);
  });

  test('a failed schedule is swallowed and the plan retries', () async {
    final binding = NotificationsBinding();
    await binding.init();
    final plan = [_reminder(id: 1, title: 'Azkar')];
    throwOn = 'zonedSchedule';

    await binding.scheduleAll(plan);

    expect(_zoned(calls), hasLength(1));

    throwOn = null;
    await binding.scheduleAll(plan);

    // Two applies, each clearing the whole planner id universe:
    expect(
      _methods(calls).where((method) => method == 'cancel'),
      hasLength(reminderAlarmIds().length * 2),
    );
    expect(_zoned(calls), hasLength(2));
  });

  test('launchPayload returns the cold-start tap payload', () async {
    final binding = NotificationsBinding();

    expect(await binding.launchPayload(), 'prayer');
  });

  test('boot grace asks for notifications when they are off and azkar is on',
      () async {
    final binding = NotificationsBinding();
    await binding.init();
    notificationsEnabled = false;

    await binding.requestBootPermission(azkarEnabled: true);

    expect(
      _methods(calls)
          .where((method) => method == 'requestNotificationsPermission'),
      hasLength(1),
    );
  });

  test('boot grace never re-prompts an opted-out user', () async {
    final binding = NotificationsBinding();
    await binding.init();

    await binding.requestBootPermission(azkarEnabled: false);

    expect(_methods(calls), isNot(contains('requestNotificationsPermission')));
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

List<MethodCall> _zoned(List<MethodCall> calls) =>
    calls.where((call) => call.method == 'zonedSchedule').toList();

List<int> _zonedIds(List<MethodCall> calls) =>
    _zoned(calls).map((call) => _arguments(call)['id'] as int).toList();

List<String?> _scheduleModes(List<MethodCall> calls) => _zoned(calls)
    .map((call) => (_arguments(call)['platformSpecifics']
        as Map<Object?, Object?>)['scheduleMode'] as String?)
    .toList();

Map<Object?, Object?> _arguments(MethodCall call) =>
    call.arguments as Map<Object?, Object?>;
