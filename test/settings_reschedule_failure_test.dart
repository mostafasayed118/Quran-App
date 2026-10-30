import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'prayer_times_cubit_test.dart'
    show FakePrayerTimeService, cairoCity, fakeDay;
import 'support/test_db.dart';

/// The write succeeds, but the schedule cannot be rebuilt.
class _ThrowingScheduler implements ReminderSchedulerPort {
  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    throw StateError('schedule down');
  }
}

void main() {
  late AppDatabase db;
  late ReminderSettings settings;
  late CityRepository city;
  late FakePrayerTimeService prayer;

  setUp(() async {
    db = newTestDb();
    settings = ReminderSettings(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    prayer = FakePrayerTimeService()
      ..todayResult = fakeDay()
      ..nextResult = fakeDay().first;
    await city.select(cairoCity);
  });

  tearDown(() async => db.close());

  SettingsCubit build() => SettingsCubit(
        settings: settings,
        city: city,
        prayer: prayer,
        scheduler: _ThrowingScheduler(),
      );

  test('a failed re-plan still shows the committed azkar enable', () async {
    final cubit = build();
    await cubit.load();

    await cubit.setAzkarEnabled(true);

    final state = cubit.state as SettingsReady;
    expect(state.azkarEnabled, isTrue);
    expect(await settings.azkarEnabled(), isTrue);
    await cubit.close();
  });

  test('a failed re-plan still shows the committed reminder time', () async {
    final cubit = build();
    await cubit.load();

    await cubit.setTime('05:15');

    final state = cubit.state as SettingsReady;
    expect(state.azkarTimeHm, '05:15');
    expect(await settings.azkarTimeHm(), '05:15');
    await cubit.close();
  });
}
