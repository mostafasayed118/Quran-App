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

void main() {
  late AppDatabase db;
  late ReminderSettings settings;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    db = newTestDb();
    settings = ReminderSettings(db);
    scheduler = FakeReminderScheduler();
  });

  /// The wird toggle (A1b) adds a second Switch; scope the azkar finder.
  Finder azkarSwitch() => find.descendant(
        of: find.widgetWithText(SwitchListTile, 'تذكير الأذكار'),
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
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<SettingsCubit>.value(value: cubit, child: app),
      home: const SettingsScreen(),
    );
  }

  testWidgets('renders the minimal surface with the persisted defaults',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('تذكير الأذكار'), findsOneWidget);
    expect(find.text('وقت التذكير'), findsOneWidget);
    expect(find.text('٠٦:٣٠'), findsOneWidget);
    expect(find.text('الوضع الليلي من إعدادات جهازك'), findsOneWidget);
    expect(tester.widget<Switch>(azkarSwitch()).value, isFalse);
    expect(
      find.text('إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'),
      findsNothing,
    );
  });

  testWidgets('toggling on persists and shows no hint when granted',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(azkarSwitch());
    await tester.pumpAndSettle();

    expect(await settings.azkarEnabled(), isTrue);
    expect(tester.widget<Switch>(azkarSwitch()).value, isTrue);
    expect(scheduler.scheduleCalls, greaterThanOrEqualTo(1));
    expect(
      find.text('إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'),
      findsNothing,
    );
  });

  testWidgets('denied permission shows the hint line', (tester) async {
    scheduler.permissionsResult = false;
    await pumpHost(tester);

    await tester.tap(azkarSwitch());
    await tester.pumpAndSettle();

    expect(
      find.text('إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'),
      findsOneWidget,
    );
  });

  testWidgets('time tile opens the material picker once enabled',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('وقت التذكير'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);

    await tester.tap(azkarSwitch());
    await tester.pumpAndSettle();
    await tester.tap(find.text('وقت التذكير'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.text('الإلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
  });
}
