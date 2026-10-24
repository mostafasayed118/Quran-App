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

class FlakyReminderSettings extends ReminderSettings {
  FlakyReminderSettings(super._db);

  bool failWrites = false;

  @override
  Future<void> setAzkarEnabled(bool enabled) async {
    if (failWrites) throw StateError('write failed');
    await super.setAzkarEnabled(enabled);
  }

  @override
  Future<void> setAzkarTime(String hm) async {
    if (failWrites) throw StateError('write failed');
    await super.setAzkarTime(hm);
  }
}

void main() {
  late AppDatabase db;
  late FlakyReminderSettings settings;
  late CityRepository city;
  late FakePrayerTimeService prayer;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    db = newTestDb();
    settings = FlakyReminderSettings(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    prayer = FakePrayerTimeService()
      ..todayResult = fakeDay()
      ..nextResult = fakeDay().first;
    scheduler = FakeReminderScheduler();
    await city.select(cairoCity);
  });

  SettingsCubit build() => SettingsCubit(
        settings: settings,
        city: city,
        prayer: prayer,
        scheduler: scheduler,
      );

  test('a failed enable write completes and keeps the last ready state',
      () async {
    final cubit = build();
    await cubit.load();

    settings.failWrites = true;
    await expectLater(cubit.setAzkarEnabled(true), completes);

    final state = cubit.state;
    expect(state, isA<SettingsReady>());
    expect((state as SettingsReady).azkarEnabled, isFalse);
    expect(scheduler.permissionCalls, 0);

    await cubit.close();
  });

  test('a failed time write keeps the last confirmed time', () async {
    final cubit = build();
    await cubit.load();
    final before = (cubit.state as SettingsReady).azkarTimeHm;

    settings.failWrites = true;
    await expectLater(cubit.setTime('05:15'), completes);

    final state = cubit.state;
    expect(state, isA<SettingsReady>());
    expect((state as SettingsReady).azkarTimeHm, before);

    await cubit.close();
  });

  test('a successful mutation after a failed one still emits', () async {
    final cubit = build();
    await cubit.load();

    settings.failWrites = true;
    await cubit.setAzkarEnabled(true);
    expect((cubit.state as SettingsReady).azkarEnabled, isFalse);

    settings.failWrites = false;
    await cubit.setAzkarEnabled(true);

    final state = cubit.state;
    expect(state, isA<SettingsReady>());
    expect((state as SettingsReady).azkarEnabled, isTrue);
    expect(await settings.azkarEnabled(), isTrue);

    await cubit.close();
  });
}
