import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/host.dart';
import 'support/test_db.dart';

/// Bounded settles: drift futures + dialog animations advance on explicit
/// pumps only (no pumpAndSettle on a live DB, per the wave brief).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ReminderSettings settings;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    db = newTestDb();
    settings = ReminderSettings(db);
    scheduler = FakeReminderScheduler();
  });

  Finder wirdSwitch() => find.descendant(
        of: find.widgetWithText(SwitchListTile, 'تذكير الورد'),
        matching: find.byType(Switch),
      );

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = SettingsCubit(
      settings: settings,
      city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
      prayer: FakePrayerTimeService(),
      scheduler: scheduler,
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<SettingsCubit>.value(value: cubit, child: app),
      home: const SettingsScreen(),
      settle: false,
    );
    await settle(tester);
  }

  testWidgets('renders the wird row off with the default time', (tester) async {
    await pumpHost(tester);

    expect(find.text('تذكير الورد'), findsOneWidget);
    expect(find.text('وقت تذكير الورد'), findsOneWidget);
    expect(find.text('٢٠:٠٠'), findsOneWidget);
    expect(tester.widget<Switch>(wirdSwitch()).value, isFalse);
  });

  testWidgets('toggling the wird persists and re-plans', (tester) async {
    await pumpHost(tester);

    await tester.tap(wirdSwitch());
    await settle(tester);

    expect(await settings.wirdEnabled(), isTrue);
    expect(tester.widget<Switch>(wirdSwitch()).value, isTrue);
    expect(scheduler.scheduleCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('the wird time tile opens the picker only once enabled',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('وقت تذكير الورد'));
    await settle(tester);
    expect(find.byType(TimePickerDialog), findsNothing);

    await tester.tap(wirdSwitch());
    await settle(tester);
    await tester.tap(find.text('وقت تذكير الورد'));
    await settle(tester);
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.text('الإلغاء'));
    await settle(tester);
    expect(find.byType(TimePickerDialog), findsNothing);
  });
}
