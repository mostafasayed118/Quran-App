import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'prayer_times_cubit_test.dart'
    show FakePrayerTimeService, cairoCity, fakeDay;
import 'support/test_db.dart';

class FakeReminderScheduler implements ReminderSchedulerPort {
  final plans = <List<ScheduledReminder>>[];
  bool permissionsResult = true;
  int permissionCalls = 0;
  int scheduleCalls = 0;

  @override
  Future<bool> ensurePermissions() async {
    permissionCalls++;
    return permissionsResult;
  }

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    scheduleCalls++;
    plans.add(reminders);
  }
}

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

  test('load emits defaults on a fresh database', () async {
    final cubit = build();
    await cubit.load();

    final state = cubit.state as SettingsReady;
    expect(state.azkarEnabled, isFalse);
    expect(state.azkarTimeHm, defaultAzkarTimeHm);
    expect(state.permissionDenied, isFalse);

    await cubit.close();
  });

  test('enabling persists, requests permission and re-plans', () async {
    await city.select(cairoCity);
    final cubit = build();
    await cubit.load();

    await cubit.setAzkarEnabled(true);

    expect(await settings.azkarEnabled(), isTrue);
    final state = cubit.state as SettingsReady;
    expect(state.azkarEnabled, isTrue);
    expect(state.permissionDenied, isFalse);
    expect(scheduler.permissionCalls, 1);
    expect(scheduler.scheduleCalls, greaterThanOrEqualTo(1));
    expect(
      scheduler.plans.last.any((r) => r.id == azkarReminderId),
      isTrue,
    );

    await cubit.close();
  });

  test('denied permission surfaces the hint flag; disabling clears it',
      () async {
    scheduler.permissionsResult = false;
    final cubit = build();
    await cubit.load();

    await cubit.setAzkarEnabled(true);
    expect((cubit.state as SettingsReady).permissionDenied, isTrue);

    await cubit.setAzkarEnabled(false);
    final state = cubit.state as SettingsReady;
    expect(state.azkarEnabled, isFalse);
    expect(state.permissionDenied, isFalse);

    await cubit.close();
  });

  test('time change persists and re-plans at the new time', () async {
    await city.select(cairoCity);
    final cubit = build();
    await cubit.load();
    await cubit.setAzkarEnabled(true);
    final callsBefore = scheduler.scheduleCalls;

    await cubit.setTime('05:15');

    expect(await settings.azkarTimeHm(), '05:15');
    expect((cubit.state as SettingsReady).azkarTimeHm, '05:15');
    expect(scheduler.scheduleCalls, callsBefore + 1);
    final azkar =
        scheduler.plans.last.singleWhere((r) => r.id == azkarReminderId);
    expect(azkar.fireAt.hour, 5);
    expect(azkar.fireAt.minute, 15);

    await cubit.close();
  });
}
