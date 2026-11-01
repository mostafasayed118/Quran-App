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

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_downloads_screen');
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: '51-53',
          reciterName: 'عبدالباسط عبدالصمد',
          moshafName: 'حفص عن عاصم - مرتل',
          server: 'https://server.mp3quran.net',
          surahList: '1',
          surahTotal: 114,
        ));
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          revelationType: 'makki',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  Future<void> insertDone({int bytes = 1572864}) async {
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '51-53',
          surahId: 1,
          status: 'done',
          path: '${tempRoot.path}${Platform.pathSeparator}audio'
              '${Platform.pathSeparator}51-53'
              '${Platform.pathSeparator}001.mp3',
          bytes: Value(bytes),
        ));
  }

  Future<DownloadsCubit> pumpScreen(WidgetTester tester) async {
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
          home: const DownloadsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('nothing installed shows the empty state', (tester) async {
    await pumpScreen(tester);

    expect(find.text('لا توجد تلاوات منزّلة بعد'), findsOneWidget);
    expect(find.byIcon(Icons.download_done_outlined), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('an installed row renders the reciter, the surah and the size',
      (tester) async {
    await insertDone();
    await pumpScreen(tester);

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.textContaining('عبدالباسط عبدالصمد'), findsOneWidget);
    expect(find.textContaining('١.٥'), findsOneWidget);
    expect(find.text('لا توجد تلاوات منزّلة بعد'), findsNothing);
  });

  testWidgets('delete asks first and cancelling keeps the row', (tester) async {
    await insertDone();
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('حذف'));
    await tester.pumpAndSettle();

    expect(find.text('سيُحذف هذا الملف من جهازك.'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('سيُحذف هذا الملف من جهازك.'), findsNothing);
    final rows = await db.select(db.downloads).get();
    expect(rows, hasLength(1), reason: 'a cancelled delete keeps the file row');
  });
}
