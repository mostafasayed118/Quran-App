import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(112),
          nameAr: 'الإخلاص',
          nameEn: 'Al-Ikhlas',
          revelationType: 'Meccan',
          ayahCount: 4,
          pagesStart: 604,
          pagesEnd: 604,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(6220),
          surahId: 112,
          numberInSurah: 1,
          juz: 30,
          page: 604,
          textUthmani: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
          textImlaei: 'قل هو الله أحد',
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(6221),
          surahId: 112,
          numberInSurah: 2,
          juz: 30,
          page: 604,
          textUthmani: 'اللَّهُ الصَّمَدُ',
          textImlaei: 'الله الصمد',
        ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = DuasCubit(
      duas: DuaRepository(
          loader: () async => [
                {
                  'id': 'a1',
                  'categoryAr': 'المنزل',
                  'categoryEn': 'Home',
                  'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
                },
              ]),
      ruqyah: RuqyahRepository(
          loader: () async => [
                {
                  'id': 'r2',
                  'kind': 'quran',
                  'surahId': 112,
                  'fromAyah': 1,
                  'toAyah': 2,
                },
              ]),
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<DuasCubit>.value(
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
        home: const DuasScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('ruqyah citation uses ornate brackets and Arabic-Indic digits',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('الرقية'));
    await tester.pumpAndSettle();

    expect(find.text('﴿الإخلاص ١–٢﴾'), findsOneWidget);
    expect(find.text('﴿الإخلاص 1–2﴾'), findsNothing,
        reason: 'citation digits must be Arabic-Indic at the call site');
  });
}
