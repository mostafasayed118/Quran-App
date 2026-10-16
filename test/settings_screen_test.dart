import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'settings_cubit_test.dart' show FakeReminderScheduler;

void main() {
  late AppDatabase db;
  late ReminderSettings settings;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    settings = ReminderSettings(db);
    scheduler = FakeReminderScheduler();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = SettingsCubit(
      settings: settings,
      city: CityRepository(db: db, loader: () async => [cairoCity.toJson()]),
      prayer: FakePrayerTimeService(),
      scheduler: scheduler,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<SettingsCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the minimal surface with the persisted defaults',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('تذكير الأذكار'), findsOneWidget);
    expect(find.text('وقت التذكير'), findsOneWidget);
    expect(find.text('٠٦:٣٠'), findsOneWidget);
    expect(find.text('الوضع الليلي من إعدادات جهازك'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(
      find.text('إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'),
      findsNothing,
    );
  });

  testWidgets('toggling on persists and shows no hint when granted',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(await settings.azkarEnabled(), isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(scheduler.scheduleCalls, greaterThanOrEqualTo(1));
    expect(
      find.text('إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'),
      findsNothing,
    );
  });

  testWidgets('denied permission shows the hint line', (tester) async {
    scheduler.permissionsResult = false;
    await pumpHost(tester);

    await tester.tap(find.byType(Switch));
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

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وقت التذكير'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);

    await tester.tap(find.text('الإلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
  });
}
