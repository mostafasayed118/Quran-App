import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = newTestDb();
    lastRead = LastReadRepository(db);
    ayahs = AyahRepository(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'Medinan',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 5,
          juz: 1,
          page: 2,
          textUthmani: 'ذلك الكتاب',
          textImlaei: 'ذلك الكتاب',
        ));
  });

  Future<void> pumpHome(
    WidgetTester tester,
    HomeCubit cubit, {
    TextScaler? textScaler,
  }) async {
    await tester.pumpWidget(BlocProvider<HomeCubit>.value(
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
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
        home: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'textScale 2.0: both cards and the full grid survive the '
      'layout', (tester) async {
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpHome(tester, cubit, textScaler: const TextScaler.linear(2.0));

    expect(tester.takeException(), isNull);
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('﴿٥﴾ متابعة القراءة'), findsOneWidget);
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('٠٤:٤٥'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets(
      'textScale 2.0: the first-run pick-city hint survives the '
      'layout', (tester) async {
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpHome(tester, cubit, textScaler: const TextScaler.linear(2.0));

    expect(tester.takeException(), isNull);
    expect(find.text('اختر مدينتك'), findsOneWidget);
    expect(find.text('لم تُحدَّد مدينة بعد'), findsOneWidget);
  });

  testWidgets(
      'a throwing load renders the localized error pane instead of '
      'an eternal spinner', (tester) async {
    await city.select(cairoCity);
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService()..throwOnNext = true,
      city: city,
    );
    addTearDown(cubit.close);
    await cubit.reload();

    await pumpHome(tester, cubit);

    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
