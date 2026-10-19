import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show Size;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/khatma_progress.dart';
import 'package:quran_yahdi/features/tracker/data/khatma_repository.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_screen.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

import 'support/host.dart';
import 'support/test_db.dart';

AyahsCompanion _ayah(int id, {required int page, required int number}) =>
    AyahsCompanion.insert(
      id: Value(id),
      surahId: 1,
      numberInSurah: number,
      juz: 1,
      page: page,
      textUthmani: 'x',
      textImlaei: 'x',
    );

/// Bounded settles: drift futures + sheet animations advance on explicit
/// pumps only (no pumpAndSettle on a live DB, per the wave brief).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late PrayerLogRepository logRepo;
  late KhatmaRepository khatmaRepo;

  setUp(() async {
    db = newTestDb();
    logRepo = PrayerLogRepository(db);
    khatmaRepo = KhatmaRepository(db);
    await db.batch((b) => b.insertAll(db.ayahs, [
          _ayah(1, page: 1, number: 1),
          _ayah(2, page: 1, number: 2),
          _ayah(9, page: 6, number: 3),
          _ayah(19, page: 11, number: 4),
          _ayah(90, page: 603, number: 5),
          _ayah(91, page: 604, number: 6),
          _ayah(6236, page: 604, number: 7),
        ]));
  });

  Future<TrackerCubit> buildCubit({bool withKhatma = true}) async {
    final cubit = TrackerCubit(
      repo: logRepo,
      khatma: withKhatma ? khatmaRepo : null,
    );
    addTearDown(cubit.close);
    await cubit.loaded;
    return cubit;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool withKhatma = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final cubit = TrackerCubit(
      repo: logRepo,
      khatma: withKhatma ? khatmaRepo : null,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      appShell(
        wrap: (app) => BlocProvider<TrackerCubit>.value(value: cubit, child: app),
        home: const TrackerScreen(),
      ),
    );
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await settle(tester);
    await tester.tap(find.text(text));
    await settle(tester);
  }

  test('without a khatma repository the card stays unavailable', () async {
    final cubit = await buildCubit(withKhatma: false);
    final ready = cubit.state as TrackerReady;
    expect(ready.khatmaAvailable, isFalse);
    expect(ready.khatma, isNull);
  });

  test('available and planless: setup state', () async {
    final cubit = await buildCubit();
    final ready = cubit.state as TrackerReady;
    expect(ready.khatmaAvailable, isTrue);
    expect(ready.khatma, isNull);
  });

  test('startKhatma(151) exposes day one of a 5-page pace', () async {
    final cubit = await buildCubit();
    await cubit.startKhatma(151);

    final p = (cubit.state as TrackerReady).khatma!;
    expect(p.pointerPage, 1);
    expect(p.dailyPages, 5);
    expect(p.todayStartPage, 1);
    expect(p.todayEndPage, 5);
    expect(p.pagesDone, 0);
    expect(p.completed, isFalse);
  });

  test('finishWirdToday advances one daily portion', () async {
    final cubit = await buildCubit();
    await cubit.startKhatma(151);
    await cubit.finishWirdToday();

    final p = (cubit.state as TrackerReady).khatma!;
    expect(p.pointerPage, 6);
    expect(p.pointerAyahId, 9);
    expect(p.todayStartPage, 6);
    expect(p.todayEndPage, 10);
    expect(p.pagesDone, 5);
  });

  test('finishing a portion that overruns the last page completes the plan',
      () async {
    final cubit = await buildCubit();
    await cubit.startKhatma(151);
    await khatmaRepo.advanceTo(90); // page 603
    await cubit.reload();

    await cubit.finishWirdToday();

    final p = (cubit.state as TrackerReady).khatma!;
    expect(p.completed, isTrue);
    expect(p.pointerAyahId, 6236);
    expect(p.pointerPage, 604);
  });

  test('resetKhatma returns the card to setup', () async {
    final cubit = await buildCubit();
    await cubit.startKhatma(604);
    await cubit.resetKhatma();

    final ready = cubit.state as TrackerReady;
    expect(ready.khatmaAvailable, isTrue);
    expect(ready.khatma, isNull);
  });

  test('wirdReaderRoute opens the reader at the pointer', () {
    const p = KhatmaProgress(
      pointerAyahId: 262,
      pointerPage: 42,
      targetPages: 302,
      readerSurahId: 2,
      readerAyahNumber: 255,
    );
    expect(wirdReaderRoute(p), '/quran/reader?surah=2&ayah=255');
  });

  testWidgets('without a khatma repository the card renders nothing',
      (tester) async {
    await pumpScreen(tester, withKhatma: false);
    expect(find.text('ورد الختمة'), findsNothing);
  });

  testWidgets('setup → sheet → active card → finish advances the range',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('ورد الختمة'), findsOneWidget);
    expect(find.text('ابدأ ختمة'), findsOneWidget);

    await tapText(tester, 'ابدأ ختمة');

    expect(find.text('وتيرة الختمة'), findsOneWidget);
    expect(find.text('ختمة كل شهر'), findsOneWidget);
    expect(find.text('ختمة كل ٤ شهور'), findsOneWidget);
    expect(find.text('٥ صفحة يوميًا تقريبًا'), findsOneWidget);

    await tapText(tester, 'ختمة كل ٤ شهور');

    expect(find.text('٠ من ٦٠٤ صفحة'), findsOneWidget);
    expect(find.text('اليوم: من صفحة ١ إلى ٥'), findsOneWidget);
    expect(find.text('باقي نحو ١٢١ يوم'), findsOneWidget);
    expect(find.text('افتح الورد'), findsOneWidget);

    await tapText(tester, 'أنهيت ورد اليوم');

    expect(find.text('٥ من ٦٠٤ صفحة'), findsOneWidget);
    expect(find.text('اليوم: من صفحة ٦ إلى ١٠'), findsOneWidget);
    expect(find.text('باقي نحو ١٢٠ يوم'), findsOneWidget);
  });

  testWidgets('completed plan shows the completion state; new khatma resets',
      (tester) async {
    await khatmaRepo.startPlan(151);
    await khatmaRepo.advanceTo(90); // page 603
    await pumpScreen(tester);

    expect(find.text('اليوم: من صفحة ٦٠٣ إلى ٦٠٤'), findsOneWidget);

    await tapText(tester, 'أنهيت ورد اليوم');

    expect(find.text('أتممت الختمة'), findsOneWidget);
    expect(find.text('ختمة جديدة'), findsOneWidget);

    await tapText(tester, 'ختمة جديدة');

    expect(find.text('ابدأ ختمة'), findsOneWidget);
    expect(find.text('أتممت الختمة'), findsNothing);
  });
}
