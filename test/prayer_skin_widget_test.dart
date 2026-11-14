import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/app.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/domain/prayer_skin.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_theme_controller.dart';
import 'package:quran_yahdi/core/theme/prayer_palette.dart';
import 'package:quran_yahdi/core/theme/prayer_skin_controller.dart';
import 'package:quran_yahdi/core/widgets/neutral_reading_theme.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/data/app_theme_repository.dart';
import 'package:quran_yahdi/features/settings/data/prayer_skin_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/fakes.dart';
import 'support/host.dart';
import 'support/test_db.dart';
import 'support/theme_roles.dart';
import 'support/theme_snapshot.dart';

int _hex(Color color) => color.toARGB32();

void main() {
  group('chromeTheme', () {
    test('fixed returns the shipped instance untouched', () {
      expect(
        identical(
          chromeTheme(
            shipped: AppTheme.light,
            followsPrayer: false,
            period: PrayerName.fajr,
          ),
          AppTheme.light,
        ),
        isTrue,
      );
    });

    test('a period that has not been computed yet keeps the shipped theme', () {
      expect(
        identical(
          chromeTheme(
            shipped: AppTheme.dark,
            followsPrayer: true,
            period: null,
          ),
          AppTheme.dark,
        ),
        isTrue,
      );
    });

    test(
        'follow swaps to the period palette and fixed restores the shipped one',
        () {
      final followed = chromeTheme(
        shipped: AppTheme.light,
        followsPrayer: true,
        period: PrayerName.fajr,
      );
      expect(
        _hex(followed.colorScheme.primary),
        _hex(PrayerPalettes.of(PrayerName.fajr, Brightness.light).primary),
      );
      expect(themeRoles(followed), isNot(shippedThemeRoles['light']));

      expect(
        identical(
          chromeTheme(
            shipped: AppTheme.light,
            followsPrayer: false,
            period: PrayerName.fajr,
          ),
          AppTheme.light,
        ),
        isTrue,
      );
    });
  });

  testWidgets('the reader keeps the shipped palette under a skin theme',
      (tester) async {
    late ThemeData seen;
    await tester.pumpWidget(
      // The widget only reads an inherited Theme, so no app shell is needed;
      // the palette sits above it exactly as the root would place it.
      Theme(
        data: AppTheme.forPrayer(PrayerName.isha, Brightness.light),
        child: NeutralReadingTheme(
          child: Builder(
            builder: (context) {
              seen = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(themeRoles(seen), shippedThemeRoles['light']);
  });

  group('the settings row', () {
    late AppDatabase db;
    late AppThemeController theme;
    late PrayerSkinController skin;

    setUp(() async {
      db = newTestDb();
      theme = AppThemeController(AppThemeRepository(db));
      await theme.load();
      skin = PrayerSkinController(PrayerSkinRepository(db));
      await skin.load();
    });

    Future<void> pumpHost(WidgetTester tester, {bool withSkin = true}) async {
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
        home: SettingsScreen(theme: theme, skin: withSkin ? skin : null),
      );
    }

    testWidgets('shows the current choice', (tester) async {
      await pumpHost(tester);

      expect(find.text('مظهر الصلاة'), findsOneWidget);
      expect(find.text('ثابت — المظهر الحالي'), findsOneWidget);
    });

    testWidgets('picking follow switches and persists', (tester) async {
      await pumpHost(tester);

      await tester.tap(find.text('مظهر الصلاة'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
      expect(find.text('يتبع الصلاة — الألوان فقط'), findsOneWidget);

      await tester.tap(find.text('يتبع الصلاة — الألوان فقط'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

      expect(skin.mode, PrayerSkinMode.follow);
      expect(await PrayerSkinRepository(db).load(), PrayerSkinMode.follow);
      expect(find.text('يتبع الصلاة — الألوان فقط'), findsOneWidget);
    });

    testWidgets('without a controller the row stays out', (tester) async {
      await pumpHost(tester, withSkin: false);

      expect(find.text('مظهر الصلاة'), findsNothing);
    });
  });
}
