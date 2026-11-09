import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_source.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/domain/juz_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_pane.dart';
import 'package:quran_yahdi/features/quran/presentation/workspace/quran_workspace_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/fake_playback_service.dart';
import 'support/host.dart';
import 'support/test_db.dart';

class _FakePageAnchors implements PageAnchorSource {
  const _FakePageAnchors();

  @override
  Future<({int surahId, int numberInSurah})?> anchorForPage(int page) async =>
      (surahId: 2, numberInSurah: 2);
}

class _JuzSource implements JuzIndexSource {
  const _JuzSource();
  @override
  Stream<List<JuzSummary>> watchJuz() => Stream.value(const [
        JuzSummary(
          juz: 1,
          firstPage: 1,
          surahId: 1,
          numberInSurah: 1,
          surahName: 'الفاتحة',
        ),
        JuzSummary(
          juz: 2,
          firstPage: 22,
          surahId: 2,
          numberInSurah: 2,
          surahName: 'البقرة',
        ),
      ]);
}

class _TestAyahRepository extends AyahRepository {
  _TestAyahRepository(super.db, {this.bookmarks = const []});

  final List<BookmarkEntry> bookmarks;

  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(bookmarks);
}

BookmarkEntry _bookmark() => const BookmarkEntry(
      ayah: Ayah(
        id: 9,
        surahId: 2,
        numberInSurah: 2,
        juz: 1,
        page: 2,
        textUthmani: 'ذلك الكتاب',
        textImlaei: 'ذلك الكتاب',
        sajda: false,
      ),
    );

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.batch((b) => b.insertAll(db.surahs, [
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 1,
              pagesStart: 1,
              pagesEnd: 1),
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 1,
              pagesStart: 2,
              pagesEnd: 2),
        ]));
    await db.batch((b) => b.insertAll(db.ayahs, [
          AyahsCompanion.insert(
              id: const Value(8),
              surahId: 1,
              numberInSurah: 1,
              juz: 1,
              page: 1,
              textUthmani: 'بسم الله الرحمن الرحيم',
              textImlaei: 'بسم الله الرحمن الرحيم'),
          AyahsCompanion.insert(
              id: const Value(9),
              surahId: 2,
              numberInSurah: 2,
              juz: 1,
              page: 2,
              textUthmani: 'ذلك الكتاب',
              textImlaei: 'ذلك الكتاب'),
        ]));
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<({int surah, int ayah})>> pumpWorkspace(
    WidgetTester tester, {
    Size size = const Size(1024, 768),
    Locale locale = const Locale('ar'),
    double? textScale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final calls = <({int surah, int ayah})>[];

    final index = SurahIndexCubit(SurahRepository(db));
    addTearDown(index.close);
    await index.start();

    final juz = JuzIndexCubit(source: const _JuzSource());
    addTearDown(juz.close);
    await juz.start();

    final bookmarks = BookmarksCubit(
      _TestAyahRepository(db, bookmarks: [_bookmark()]),
    );
    addTearDown(bookmarks.close);
    await bookmarks.start();

    final playback = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
    );
    addTearDown(playback.close);

    ReaderCubit createReader(int surah, int ayah) {
      calls.add((surah: surah, ayah: ayah));
      return ReaderCubit(
        ayahRepository: _TestAyahRepository(db),
        lastReadRepository: LastReadRepository(db),
        surahId: surah,
        initialAyah: ayah,
        pageAnchors: const _FakePageAnchors(),
      );
    }

    await pumpAppHost(
      tester,
      locale: locale,
      textScale: textScale,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SurahIndexCubit>.value(value: index),
          BlocProvider<JuzIndexCubit>.value(value: juz),
          BlocProvider<BookmarksCubit>.value(value: bookmarks),
          BlocProvider<PlaybackCubit>.value(value: playback),
        ],
        child: QuranWorkspaceScreen(createReader: createReader),
      ),
    );

    return calls;
  }

  Finder tab(String label) => find.descendant(
        of: find.byType(TabBar),
        matching: find.text(label),
      );

  Future<void> openTab(WidgetTester tester, String label) async {
    final target = tab(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.tap(target);
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  Finder surahRow(String name) => find.descendant(
        of: find.byKey(const Key('quran-master')),
        matching: find.text(name),
      );

  testWidgets('the expanded workspace shows three tabs and the prompt',
      (tester) async {
    await pumpWorkspace(tester);

    expect(find.byType(QuranWorkspaceScreen), findsOneWidget);
    expect(tab('سور'), findsOneWidget);
    expect(tab('أجزاء'), findsOneWidget);
    expect(tab('علامات'), findsOneWidget);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);
  });

  testWidgets('tapping a surah opens the pane and back clears it',
      (tester) async {
    final calls = await pumpWorkspace(tester);

    await tester.tap(surahRow('الفاتحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(calls, [(surah: 1, ayah: 0)]);
    expect(find.byType(ReaderPane), findsOneWidget);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(ReaderPane), findsNothing);
    expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);
  });

  testWidgets('tapping a juz opens the reader at its first ayah',
      (tester) async {
    final calls = await pumpWorkspace(tester);

    await openTab(tester, 'أجزاء');
    await tester.tap(find.text('الجزء ١'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(calls, [(surah: 1, ayah: 1)]);
    expect(find.byType(ReaderPane), findsOneWidget);
  });

  testWidgets('tapping a bookmark opens the reader at the verse',
      (tester) async {
    final calls = await pumpWorkspace(tester);

    await openTab(tester, 'علامات');
    await tester.tap(find.text('ذلك الكتاب'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(calls, [(surah: 2, ayah: 2)]);
    expect(find.byType(ReaderPane), findsOneWidget);
  });

  testWidgets('switching tabs keeps the search and the open reader',
      (tester) async {
    await pumpWorkspace(tester);

    await tester.tap(surahRow('الفاتحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.enterText(find.byType(TextField), 'بقرة');
    await tester.pump();

    await openTab(tester, 'أجزاء');
    await openTab(tester, 'سور');

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'بقرة',
    );
    expect(find.byType(ReaderPane), findsOneWidget);
  });

  testWidgets('re-selecting the same surah keeps one pane and one cubit',
      (tester) async {
    final calls = await pumpWorkspace(tester);

    await tester.tap(surahRow('الفاتحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.tap(surahRow('الفاتحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(calls, [(surah: 1, ayah: 0)]);
    expect(find.byType(ReaderPane), findsOneWidget);
  });

  testWidgets('textScale 2.0 keeps the tabs scrollable and overflow-free',
      (tester) async {
    await pumpWorkspace(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
  });

  testWidgets('English puts the master pane on the left', (tester) async {
    await pumpWorkspace(tester, locale: const Locale('en'));

    final master = tester.getTopLeft(find.byKey(const Key('quran-master')));
    final detail = tester.getTopLeft(find.byKey(const Key('quran-detail')));
    expect(master.dx, lessThan(detail.dx));
  });

  testWidgets('page jump resolves inside the pane', (tester) async {
    final calls = await pumpWorkspace(tester);

    await tester.tap(surahRow('الفاتحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.tap(find.byTooltip('الانتقال إلى صفحة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '2',
    );
    await tester.tap(find.text('انتقال'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(calls.last, (surah: 2, ayah: 2));
    expect(find.byType(ReaderPane), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReaderPane),
        matching: find.text('البقرة'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching tabs releases the IME focus', (tester) async {
    await pumpWorkspace(tester);

    await tester.enterText(find.byType(TextField), 'بقرة');
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await openTab(tester, 'أجزاء');

    final hidden = tester.widget<EditableText>(
      find.byType(EditableText, skipOffstage: false),
    );
    expect(hidden.focusNode.hasFocus, isFalse);
  });

  testWidgets('all three tab labels fit the 340 dp master', (tester) async {
    await pumpWorkspace(tester);

    final master = tester.getRect(find.byKey(const Key('quran-master')));
    for (final label in const ['سور', 'أجزاء', 'علامات']) {
      final rect = tester.getRect(tab(label));
      expect(rect.left, greaterThanOrEqualTo(master.left - 0.5));
      expect(rect.right, lessThanOrEqualTo(master.right + 0.5));
    }
  });
}
