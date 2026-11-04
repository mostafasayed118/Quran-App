import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_theme_controller.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/data/app_theme_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late AppThemeController theme;

  setUp(() async {
    db = newTestDb();
    theme = AppThemeController(AppThemeRepository(db));
    await theme.load();
  });

  Future<void> pumpHost(WidgetTester tester) async {
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
      home: SettingsScreen(theme: theme),
    );
  }

  testWidgets('the appearance row shows the current mode', (tester) async {
    await pumpHost(tester);

    expect(find.text('المظهر'), findsOneWidget);
    expect(find.text('حسب النظام'), findsOneWidget);
  });

  testWidgets('picking dark switches and persists the mode', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('المظهر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('غامق'));
    await tester.pumpAndSettle();

    expect(theme.mode, AppThemeMode.dark);
    expect(await AppThemeRepository(db).load(), AppThemeMode.dark);
  });

  testWidgets('dismissing the dialog leaves the mode alone', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('المظهر'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(theme.mode, AppThemeMode.system);
  });

  testWidgets('without a controller the row stays out', (tester) async {
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
    );

    expect(find.text('المظهر'), findsNothing);
  });
}
