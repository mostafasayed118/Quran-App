import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'prayer_times_cubit_test.dart'
    show FakePrayerTimeService, cairoCity, fakeDay;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late ReminderSettings settings;
  late CityRepository city;
  late FakePrayerTimeService prayer;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    db = newTestDb();
    settings = ReminderSettings(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    prayer = FakePrayerTimeService()
      ..todayResult = fakeDay()
      ..nextResult = fakeDay().first;
    scheduler = FakeReminderScheduler();
  });

  SettingsCubit build() => SettingsCubit(
        settings: settings,
        city: city,
        prayer: prayer,
        scheduler: scheduler,
      );

  test('load emits wird defaults on a fresh database', () async {
    final cubit = build();
    await cubit.load();

    final state = cubit.state as SettingsReady;
    expect(state.wirdEnabled, isFalse);
    expect(state.wirdTimeHm, defaultWirdTimeHm);

    await cubit.close();
  });

  test('enabling the wird persists, requests permission and re-plans',
      () async {
    await city.select(cairoCity);
    final cubit = build();
    await cubit.load();

    await cubit.toggleWird(true);

    expect(await settings.wirdEnabled(), isTrue);
    final state = cubit.state as SettingsReady;
    expect(state.wirdEnabled, isTrue);
    expect(state.permissionDenied, isFalse);
    expect(scheduler.permissionCalls, 1);
    expect(scheduler.scheduleCalls, greaterThanOrEqualTo(1));
    final wird =
        scheduler.plans.last.singleWhere((r) => r.id == wirdReminderId);
    expect(wird.fireAt.hour, 20);
    expect(wird.fireAt.minute, 0);

    await cubit.close();
  });

  test('denied permission surfaces the hint flag; disabling clears it',
      () async {
    scheduler.permissionsResult = false;
    final cubit = build();
    await cubit.load();

    await cubit.toggleWird(true);
    expect((cubit.state as SettingsReady).permissionDenied, isTrue);

    await cubit.toggleWird(false);
    final state = cubit.state as SettingsReady;
    expect(state.wirdEnabled, isFalse);
    expect(state.permissionDenied, isFalse);

    await cubit.close();
  });

  test('wird time change persists and re-plans at the new time', () async {
    await city.select(cairoCity);
    final cubit = build();
    await cubit.load();
    await cubit.toggleWird(true);
    final callsBefore = scheduler.scheduleCalls;

    await cubit.changeWirdTime('21:45');

    expect(await settings.wirdTimeHm(), '21:45');
    expect((cubit.state as SettingsReady).wirdTimeHm, '21:45');
    expect(scheduler.scheduleCalls, callsBefore + 1);
    final wird =
        scheduler.plans.last.singleWhere((r) => r.id == wirdReminderId);
    expect(wird.fireAt.hour, 21);
    expect(wird.fireAt.minute, 45);

    await cubit.close();
  });

  test('azkar edits preserve the wird selection in state', () async {
    final cubit = build();
    await cubit.load();
    await cubit.toggleWird(true);
    await cubit.changeWirdTime('21:00');

    await cubit.setAzkarEnabled(true);

    final state = cubit.state as SettingsReady;
    expect(state.wirdEnabled, isTrue);
    expect(state.wirdTimeHm, '21:00');

    await cubit.close();
  });
}
