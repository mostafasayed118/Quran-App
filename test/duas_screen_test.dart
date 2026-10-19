import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/widgets/async_view.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DuaRepository duaRepo;
  late RuqyahRepository ruqyahRepo;

  setUp(() async {
    db = newTestDb();
    duaRepo = DuaRepository(
        loader: () async => [
              {
                'id': 'a1',
                'categoryAr': 'المنزل',
                'categoryEn': 'Home',
                'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
              },
              {
                'id': 'a2',
                'categoryAr': 'السفر',
                'categoryEn': 'Travel',
                'text': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا',
              },
            ]);
    ruqyahRepo = RuqyahRepository(
        loader: () async => [
              {
                'id': 'r1',
                'kind': 'dhikr',
                'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
                'count': 3
              },
              {
                'id': 'r2',
                'kind': 'quran',
                'surahId': 112,
                'fromAyah': 1,
                'toAyah': 2
              },
            ]);
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

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = DuasCubit(
      duas: duaRepo,
      ruqyah: ruqyahRepo,
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<DuasCubit>.value(value: cubit, child: app),
      home: const DuasScreen(),
    );
  }

  testWidgets('duas tab lists entries and filters by category chip',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('بِسْمِ اللَّهِ وَلَجْنَا'), findsOneWidget);
    expect(find.text('سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا'), findsOneWidget);

    await tester.tap(find.text('المنزل'));
    await tester.pumpAndSettle();
    expect(find.text('بِسْمِ اللَّهِ وَلَجْنَا'), findsOneWidget);
    expect(find.text('سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا'), findsNothing);
  });

  testWidgets('ruqyah tab resolves quran ranges from the DB shows citation',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('الرقية'));
    await tester.pumpAndSettle();

    expect(find.textContaining('أَعُوذُ بِكَلِمَاتِ اللَّهِ'), findsOneWidget);
    expect(find.text('قُلْ هُوَ اللَّهُ أَحَدٌ اللَّهُ الصَّمَدُ'),
        findsOneWidget);
    expect(find.textContaining('الإخلاص'), findsOneWidget);
    expect(find.text('×٣'), findsOneWidget);
  });

  testWidgets('duas load failure lands in the error pane, never hangs',
      (tester) async {
    final cubit = DuasCubit(
      duas: DuaRepository(loader: () async => throw StateError('duas down')),
      ruqyah: ruqyahRepo,
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
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorView), findsOneWidget);
  });
}
