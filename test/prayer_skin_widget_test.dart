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

  group('the reader stays neutral', () {
    for (final (name, brightness) in const [
      (PrayerName.fajr, Brightness.dark),
      (PrayerName.sunrise, Brightness.light),
      (PrayerName.isha, Brightness.light),
    ]) {
      testWidgets('${name.name}/${brightness.name} resolves the shipped roles',
          (tester) async {
        late ThemeData seen;
        await pumpAppHost(
          tester,
          theme: AppTheme.forPrayer(name, brightness),
          home: NeutralReadingTheme(
            child: Builder(
              builder: (context) {
                seen = Theme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(themeRoles(seen), shippedThemeRoles[brightness.name]);
      });
    }

    testWidgets(
        'a brightness change while the reader is open swaps to that '
        'shipped theme', (tester) async {
      final brightness = ValueNotifier(Brightness.light);
      addTearDown(brightness.dispose);
      late ThemeData seen;
      await tester.pumpWidget(
        ValueListenableBuilder<Brightness>(
          valueListenable: brightness,
          builder: (_, value, __) => Theme(
            data: AppTheme.forPrayer(PrayerName.fajr, value),
            child: NeutralReadingTheme(
              child: Builder(
                builder: (context) {
                  seen = Theme.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(themeRoles(seen), shippedThemeRoles['light']);

      brightness.value = Brightness.dark;
      await tester.pump();

      expect(themeRoles(seen), shippedThemeRoles['dark']);
    });

    testWidgets('a dialog opened from the reader captures the neutral theme',
        (tester) async {
      late ThemeData dialogTheme;
      await pumpAppHost(
        tester,
        theme: AppTheme.forPrayer(PrayerName.isha, Brightness.light),
        home: NeutralReadingTheme(
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      dialogTheme = Theme.of(dialogContext);
                      return const AlertDialog(content: Text('dialog'));
                    },
                  ),
                  child: const Text('open dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

      expect(themeRoles(dialogTheme), shippedThemeRoles['light']);
      final dialogMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        dialogMaterial.color?.toARGB32(),
        AppTheme.light.colorScheme.surfaceContainerHigh.toARGB32(),
      );
    });

    testWidgets('a modal sheet opened from the reader is neutral and separated',
        (tester) async {
      late ThemeData sheetTheme;
      await pumpAppHost(
        tester,
        theme: AppTheme.forPrayer(PrayerName.isha, Brightness.light),
        home: NeutralReadingTheme(
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (sheetContext) {
                      sheetTheme = Theme.of(sheetContext);
                      return const SizedBox(height: 80);
                    },
                  ),
                  child: const Text('open sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

      expect(themeRoles(sheetTheme), shippedThemeRoles['light']);
      final sheetMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      // Neutral sheet: the shipped role, and not the card fill it covers.
      expect(
        sheetMaterial.color?.toARGB32(),
        AppTheme.light.colorScheme.surfaceContainerLow.toARGB32(),
      );
      expect(
        sheetMaterial.color?.toARGB32(),
        isNot(AppTheme.light.colorScheme.surface.toARGB32()),
      );
    });

    testWidgets('a raw SnackBar in the reader uses the neutral snackbar theme',
        (tester) async {
      await pumpAppHost(
        tester,
        theme: AppTheme.forPrayer(PrayerName.isha, Brightness.light),
        home: NeutralReadingTheme(
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('raw')),
                  ),
                  child: const Text('raw toast'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('raw toast'));
      await tester.pump();

      final material = tester.widget<Material>(
        find
            .descendant(
                of: find.byType(SnackBar), matching: find.byType(Material))
            .first,
      );
      expect(
        material.color?.toARGB32(),
        AppTheme.light.colorScheme.surface.toARGB32(),
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    });
  });

  group('the chrome sheet', () {
    testWidgets('is separated from a card in a light and a dark period',
        (tester) async {
      for (final (name, brightness) in const [
        (PrayerName.dhuhr, Brightness.light),
        (PrayerName.isha, Brightness.dark),
      ]) {
        final palette = PrayerPalettes.of(name, brightness);
        await pumpAppHost(
          tester,
          theme: AppTheme.forPrayer(name, brightness),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 80),
                  ),
                  child: const Text('chrome sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('chrome sheet'));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 10),
        );

        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Material),
              )
              .first,
        );
        final fill = material.color!;
        expect(fill.toARGB32(), palette.sheetSurface.toARGB32());
        expect(fill.toARGB32(), isNot(palette.surface.toARGB32()));

        await tester.tapAt(const Offset(8, 8)); // Dismiss the sheet.
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 10),
        );
      }
    });
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
