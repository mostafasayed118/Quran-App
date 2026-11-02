import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/reminder_diagnostics.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/host.dart';
import 'support/test_db.dart';

// The shipped Arabic copy (app_ar.arb) the section must render.
const String _title = 'موثوقية التذكيرات';
const String _notificationsIssue =
    'إذن الإشعارات مغلق — فعِّله من إعدادات جهازك.';
const String _exactAlarmsIssue =
    'التنبيهات الدقيقة غير مسموحة — قد تتأخر التذكيرات.';
const String _batteryIssue =
    'تحسين استهلاك البطارية قد يوقف التذكيرات — استثنِ التطبيق.';
const String _batteryUnknown =
    'تعذّر فحص تحسين استهلاك البطارية — تأكد من استثناء التطبيق من تحسين البطارية يدويًا.';
const String _fixAction = 'إصلاح';

/// A diagnostics double: the reads answer from mutable fields, so a test can
/// change the device state between a pump and a resume.
class FakeReminderDiagnostics implements ReminderDiagnostics {
  bool notifications = true;
  bool exactAlarms = true;
  bool? battery = true;
  int batteryOpens = 0;
  int exactAlarmOpens = 0;

  @override
  Future<bool> notificationsEnabled() async => notifications;

  @override
  Future<bool> exactAlarmsAllowed() async => exactAlarms;

  @override
  Future<bool?> batteryOptimizationIgnored() async => battery;

  @override
  Future<bool> openBatteryOptimizationSettings() async {
    batteryOpens++;
    return true;
  }

  @override
  Future<bool> openExactAlarmSettings() async {
    exactAlarmOpens++;
    return true;
  }
}

void main() {
  late AppDatabase db;
  late FakeReminderDiagnostics diagnostics;

  setUp(() {
    db = newTestDb();
    diagnostics = FakeReminderDiagnostics();
  });

  /// Bounded settle: drift futures advance on explicit pumps only (no
  /// pumpAndSettle on a live DB, per the wave brief).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpSettings(WidgetTester tester, {double? textScale}) async {
    final cubit = SettingsCubit(
      settings: ReminderSettings(db),
      city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
      prayer: FakePrayerTimeService(),
      scheduler: FakeReminderScheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      textScale: textScale,
      wrap: (app) =>
          BlocProvider<SettingsCubit>.value(value: cubit, child: app),
      home: SettingsScreen(reminderDiagnostics: diagnostics),
      settle: false,
    );
    await settle(tester);
  }

  testWidgets('a healthy device adds no section', (tester) async {
    await pumpSettings(tester);

    expect(find.text(_title), findsNothing);
    expect(find.text(_fixAction), findsNothing);
  });

  testWidgets('a single issue shows its row and its fix action',
      (tester) async {
    diagnostics.exactAlarms = false;
    await pumpSettings(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_exactAlarmsIssue), findsOneWidget);
    expect(find.text(_fixAction), findsOneWidget);
    expect(find.text(_notificationsIssue), findsNothing);
    expect(find.text(_batteryIssue), findsNothing);
    expect(find.text(_batteryUnknown), findsNothing);

    await tester.tap(find.text(_fixAction));
    await settle(tester);

    expect(diagnostics.exactAlarmOpens, 1);
    expect(diagnostics.batteryOpens, 0);
  });

  testWidgets('a battery restriction opens the battery screen', (tester) async {
    diagnostics.battery = false;
    await pumpSettings(tester);

    expect(find.text(_batteryIssue), findsOneWidget);
    await tester.tap(find.text(_fixAction));
    await settle(tester);

    expect(diagnostics.batteryOpens, 1);
    expect(diagnostics.exactAlarmOpens, 0);
  });

  testWidgets('an unreadable battery state gives instructions, not a button',
      (tester) async {
    diagnostics.battery = null;
    await pumpSettings(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_batteryUnknown), findsOneWidget);
    expect(find.text(_fixAction), findsNothing);
    expect(find.text(_batteryIssue), findsNothing);
  });

  testWidgets('a platform without battery optimisation shows no section',
      (tester) async {
    // Reset in the body too: the widget binding asserts that debug foundation
    // variables are unset before tearDown callbacks run.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    try {
      // On iOS the channel has no handler, so it answers (true, true, null).
      // That null must not become a permanent, unfixable row: there is no
      // battery-optimisation screen on that platform to send the user to.
      diagnostics.battery = null;
      await pumpSettings(tester);

      expect(find.text(_title), findsNothing);
      expect(find.text(_batteryUnknown), findsNothing);
      expect(find.text(_fixAction), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a denied notification permission shows the permission row',
      (tester) async {
    diagnostics.notifications = false;
    await pumpSettings(tester);

    expect(find.text(_notificationsIssue), findsOneWidget);
    // No platform screen to open for the permission itself: the copy tells
    // the user where to grant it, and the row carries no action.
    expect(find.text(_fixAction), findsNothing);
  });

  testWidgets('resuming re-reads the device state', (tester) async {
    addTearDown(
      () => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    diagnostics.exactAlarms = false;
    await pumpSettings(tester);

    expect(find.text(_exactAlarmsIssue), findsOneWidget);

    diagnostics.exactAlarms = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);

    expect(find.text(_exactAlarmsIssue), findsNothing);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('all three issues render at textScaler 2.0 without overflow',
      (tester) async {
    diagnostics
      ..notifications = false
      ..exactAlarms = false
      ..battery = false;
    await pumpSettings(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text(_notificationsIssue), findsOneWidget);
    expect(find.text(_exactAlarmsIssue), findsOneWidget);
    expect(find.text(_batteryIssue), findsOneWidget);
    expect(find.text(_fixAction), findsNWidgets(2));
  });

  testWidgets('without a diagnostics dependency the section stays out',
      (tester) async {
    final cubit = SettingsCubit(
      settings: ReminderSettings(db),
      city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
      prayer: FakePrayerTimeService(),
      scheduler: FakeReminderScheduler(),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<SettingsCubit>.value(value: cubit, child: app),
      home: const SettingsScreen(),
      settle: false,
    );
    await settle(tester);

    expect(find.text(_title), findsNothing);
    expect(find.text(_fixAction), findsNothing);
  });
}
