import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

/// Bounded settles: the registry reads resolve on explicit pumps only.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_downloads_header');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          revelationType: 'makki',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'madani',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  Future<void> insertDone(int surahNumber, int bytes) async {
    await db.into(db.downloads).insert(
          DownloadsCompanion.insert(
            reciterId: '51-53',
            surahId: surahNumber,
            status: 'done',
            // Outside the audio root, so a removal skips the physical delete:
            // a widget test has no real file I/O under its fake clock.
            path: 'missing.mp3',
            bytes: Value(bytes),
          ),
        );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    final cubit = DownloadsCubit(
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<DownloadsCubit>.value(
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const DownloadsScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('two installed rows show the total and the count',
      (tester) async {
    await insertDone(1, 1572864); // 1.5 MB
    await insertDone(2, 2097152); // 2.0 MB
    await pumpScreen(tester);

    expect(find.text('المساحة المستخدمة: ٣.٥ م.ب'), findsOneWidget);
    expect(find.text('٢ سورة منزّلة'), findsOneWidget);
    expect(find.text('حذف الكل'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('a single installed row renders no header', (tester) async {
    await insertDone(1, 1572864);
    await pumpScreen(tester);

    expect(find.textContaining('المساحة المستخدمة'), findsNothing);
    expect(find.text('حذف الكل'), findsNothing);
    // The row's own size label stays the only match (R7).
    expect(find.textContaining('١.٥'), findsOneWidget);
  });

  testWidgets('an empty registry renders no header', (tester) async {
    await pumpScreen(tester);

    expect(find.text('لا توجد تلاوات منزّلة بعد'), findsOneWidget);
    expect(find.textContaining('المساحة المستخدمة'), findsNothing);
    expect(find.text('حذف الكل'), findsNothing);
  });

  testWidgets('delete all confirms first and clears the list', (tester) async {
    await insertDone(1, 1572864);
    await insertDone(2, 2097152);
    await pumpScreen(tester);

    await tester.tap(find.text('حذف الكل'));
    await settle(tester);
    expect(find.text('ستُحذف كل التلاوات المنزّلة من جهازك.'), findsOneWidget);

    await tester.tap(find.text('حذف'));
    await settle(tester);

    expect(find.text('لا توجد تلاوات منزّلة بعد'), findsOneWidget);
    expect(find.text('حذف الكل'), findsNothing);
    expect(await db.select(db.downloads).get(), isEmpty);
  });

  testWidgets('the header survives a 2.0 text scale', (tester) async {
    await insertDone(1, 1572864);
    await insertDone(2, 2097152);
    await pumpScreen(tester, textScale: 2);

    expect(find.text('المساحة المستخدمة: ٣.٥ م.ب'), findsOneWidget);
    expect(find.text('حذف الكل'), findsOneWidget);
  });
}
