import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
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
    scheduler = FakeReminderScheduler()..permissionsResult = false;
    await city.select(cairoCity);
  });

  test('permission denial is tracked per reminder', () async {
    final cubit = SettingsCubit(
      settings: settings,
      city: city,
      prayer: prayer,
      scheduler: scheduler,
    );
    await cubit.load();

    await cubit.setAzkarEnabled(true);
    var ready = cubit.state as SettingsReady;
    expect(ready.azkarPermissionDenied, isTrue);
    expect(ready.wirdPermissionDenied, isFalse);
    expect(ready.permissionDenied, isTrue);

    await cubit.toggleWird(true);
    ready = cubit.state as SettingsReady;
    expect(ready.azkarPermissionDenied, isTrue);
    expect(ready.wirdPermissionDenied, isTrue);

    await cubit.setAzkarEnabled(false);
    ready = cubit.state as SettingsReady;
    expect(ready.azkarPermissionDenied, isFalse);
    expect(ready.wirdPermissionDenied, isTrue);
    expect(ready.permissionDenied, isTrue);

    await cubit.toggleWird(false);
    ready = cubit.state as SettingsReady;
    expect(ready.azkarPermissionDenied, isFalse);
    expect(ready.wirdPermissionDenied, isFalse);
    expect(ready.permissionDenied, isFalse);

    await cubit.close();
  });
}
