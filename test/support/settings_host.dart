import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';

import 'fake_reminder_scheduler.dart';
import 'fakes.dart';
import 'host.dart';
import 'prayer_fixtures.dart' show FakePrayerTimeService;

/// Pumps the settings screen with a started [SettingsCubit] over [db].
///
/// The settings rows share one host: the only per-test difference is which
/// controller the screen is given ([home]), so each row test passes its own
/// `SettingsScreen(...)` instead of re-declaring the harness.
Future<void> pumpSettingsHost(
  WidgetTester tester, {
  required AppDatabase db,
  required Widget home,
}) async {
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
    wrap: (app) => BlocProvider<SettingsCubit>.value(value: cubit, child: app),
    home: home,
  );
}
