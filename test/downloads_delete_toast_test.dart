import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_downloads_toast');
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
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '51-53',
          surahId: 1,
          status: 'done',
          // Outside the downloader's audio root, so removal never touches the
          // real filesystem: a widget test cannot await real file I/O.
          path: '${tempRoot.path}${Platform.pathSeparator}elsewhere'
              '${Platform.pathSeparator}001.mp3',
          bytes: const Value(1572864),
        ));
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  testWidgets('a confirmed delete confirms that the file is gone',
      (tester) async {
    final cubit = DownloadsCubit(
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<DownloadsCubit>.value(
        value: cubit,
        child: appShell(home: const DownloadsScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.byTooltip('حذف'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    // The dialog title and its confirm button share the word "حذف".
    await tester.tap(find.widgetWithText(TextButton, 'حذف'));
    // Bounded pumps: `pumpAndSettle` would keep advancing fake time while the
    // reload spinner animates and let the 3 s toast expire before the assert.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تم حذف التنزيل'), findsOneWidget);
    expect(await db.select(db.downloads).get(), isEmpty);
    expect(find.text('لا توجد تلاوات منزّلة بعد'), findsOneWidget);

    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  });
}
