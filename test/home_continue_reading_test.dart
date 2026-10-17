import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
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
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'the continue-reading template lives in ARB with the digit at the '
      'call site', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(ar.continueReadingAyah('٥'), '﴿٥﴾ متابعة القراءة');
    expect(ar.continueReadingAyah('١٢'), '﴿١٢﴾ متابعة القراءة');
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.continueReadingAyah('5'), '﴿5﴾ Continue Reading');
  });

  testWidgets(
      'the home subtitle renders the ARB template with Arabic-Indic '
      'digits', (tester) async {
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);
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
        home: const HomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('﴿٥﴾ متابعة القراءة'), findsOneWidget);
  });
}
