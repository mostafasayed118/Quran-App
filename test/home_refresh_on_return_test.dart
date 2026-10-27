import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/route_observer.dart';
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

Future<void> _pumpRounds(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
}

void main() {
  testWidgets('returning to Home reloads the continue-reading card',
      (tester) async {
    final db = newTestDb();
    addTearDown(db.close);
    final lastRead = LastReadRepository(db);
    final ayahs = AyahRepository(db);
    final city =
        CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
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
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(20),
          surahId: 2,
          numberInSurah: 6,
          juz: 1,
          page: 2,
          textUthmani: 'هدى للمتقين',
          textImlaei: 'هدى للمتقين',
        ));
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

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [appRouteObserver],
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: BlocProvider<HomeCubit>.value(
          value: cubit, child: const HomeScreen()),
    ));
    await _pumpRounds(tester);
    expect(find.text('﴿٥﴾ متابعة القراءة'), findsOneWidget);

    await lastRead.saveAyahId(20);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('reader')))));
    await _pumpRounds(tester);
    nav.pop();
    await _pumpRounds(tester);

    expect(find.text('﴿٦﴾ متابعة القراءة'), findsOneWidget);
  });
}
