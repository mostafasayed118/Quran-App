import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/fake_playback_service.dart';
import 'support/host.dart';
import 'support/test_db.dart';

class _QuietBookmarks extends AyahRepository {
  _QuietBookmarks(super.db);

  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'madani',
          ayahCount: 2,
          pagesStart: 2,
          pagesEnd: 2,
        ));
    await db.batch((b) => b.insertAll(db.ayahs, [
          AyahsCompanion.insert(
            id: const Value(101),
            surahId: 2,
            numberInSurah: 1,
            juz: 1,
            page: 2,
            textUthmani: 'الم',
            textImlaei: 'الم',
          ),
          AyahsCompanion.insert(
            id: const Value(102),
            surahId: 2,
            numberInSurah: 2,
            juz: 1,
            page: 2,
            textUthmani: 'ذلك الكتاب',
            textImlaei: 'ذلك الكتاب',
          ),
        ]));
  });

  Future<void> pumpReader(WidgetTester tester) async {
    final cubit = ReaderCubit(
      ayahRepository: _QuietBookmarks(db),
      lastReadRepository: LastReadRepository(db),
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);
    await cubit.start();
    final playbackCubit = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db,
          audioRootResolver: () async => Directory.systemTemp),
    );
    addTearDown(playbackCubit.close);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<ReaderCubit>.value(value: cubit),
        BlocProvider<PlaybackCubit>.value(value: playbackCubit),
      ],
      child: appShell(home: const ReaderScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  testWidgets('a page outside 1..604 reports the error toast', (tester) async {
    await pumpReader(tester);

    await tester.tap(find.byTooltip('الانتقال إلى صفحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.enterText(find.byType(TextField), '999');
    await tester.tap(find.widgetWithText(FilledButton, 'انتقال'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
    expect(find.text('صفحة غير موجودة'), findsOneWidget);

    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  });

  testWidgets('a non-numeric page keeps the dialog and reports the error',
      (tester) async {
    await pumpReader(tester);

    await tester.tap(find.byTooltip('الانتقال إلى صفحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'انتقال'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'an invalid entry must not close the dialog silently');
    expect(find.text('صفحة غير موجودة'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  });

  testWidgets('a narrow reader folds mode and font into one menu',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpReader(tester);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byTooltip('حجم الخط'), findsNothing);
    expect(find.byTooltip('وضع المصحف'), findsNothing);
    expect(find.byTooltip('الانتقال إلى صفحة'), findsOneWidget);
    // The title scales down instead of ellipsizing in the narrow bar.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
  });
}
