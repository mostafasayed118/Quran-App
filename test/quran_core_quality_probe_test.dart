import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

Future<dynamic> _syncDecode(String path) async =>
    jsonDecode(File(path).readAsStringSync());

class _TeardownSafeSurahRepository extends SurahRepository {
  _TeardownSafeSurahRepository(super.db, this._rows);
  final List<Surah> _rows;
  @override
  Stream<List<Surah>> watchAll() => Stream.value(_rows);
}

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

class _StaticBookmarksRepository extends AyahRepository {
  _StaticBookmarksRepository(super.db, {required this.entries});
  final List<BookmarkEntry> entries;
  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(entries);
}

class _FakePlaybackService implements PlaybackService {
  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_quran_probe');
    await db.batch((b) => b.insertAll(db.surahs, [
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 7,
              pagesStart: 1,
              pagesEnd: 1),
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 3,
              pagesStart: 2,
              pagesEnd: 3),
        ]));
    await db.batch((b) => b.insertAll(db.ayahs, [
          AyahsCompanion.insert(
              id: const Value(8),
              surahId: 2,
              numberInSurah: 1,
              juz: 1,
              page: 2,
              textUthmani: 'الم',
              textImlaei: 'الم'),
          AyahsCompanion.insert(
              id: const Value(9),
              surahId: 2,
              numberInSurah: 2,
              juz: 1,
              page: 2,
              textUthmani: 'ذلك الكتاب',
              textImlaei: 'ذلك الكتاب'),
          AyahsCompanion.insert(
              id: const Value(10),
              surahId: 2,
              numberInSurah: 3,
              juz: 1,
              page: 3,
              textUthmani: 'الذين يؤمنون',
              textImlaei: 'الذين يؤمنون'),
        ]));
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  Widget localizedShell(Widget home,
      {Locale locale = const Locale('ar'), TextScaler? textScaler}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
      home: home,
    );
  }

  Future<void> pumpIndex(WidgetTester tester,
      {Locale locale = const Locale('ar'), TextScaler? textScaler}) async {
    final rows = await db.select(db.surahs).get();
    await tester.pumpWidget(localizedShell(
      BlocProvider<SurahIndexCubit>(
        create: (_) => SurahIndexCubit(_TeardownSafeSurahRepository(db, rows)),
        child: const SurahIndexScreen(),
      ),
      locale: locale,
      textScaler: textScaler,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('textScale 2.0: the surah index rows survive the layout',
      (tester) async {
    await pumpIndex(tester, textScaler: const TextScaler.linear(2.0));

    expect(tester.takeException(), isNull);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
  });

  testWidgets('the surah-row chevron follows the ambient direction',
      (tester) async {
    await pumpIndex(tester);
    expect(find.byIcon(Icons.chevron_left), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await pumpIndex(tester, locale: const Locale('en'));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });

  testWidgets(
      'textScale 2.0: the reader (verses + mushaf) and the ayah sheet survive',
      (tester) async {
    await getIt.reset();
    getIt.registerLazySingleton<PackDownloader>(() => PackDownloader(db,
        libraryRootResolver: () async => tempRoot, fileDecoder: _syncDecode));
    addTearDown(getIt.reset);

    final cubit = ReaderCubit(
      ayahRepository: _TeardownSafeAyahRepository(db),
      lastReadRepository: LastReadRepository(db),
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);
    final playbackCubit = PlaybackCubit(
      service: _FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db,
          audioRootResolver: () async => Directory.systemTemp),
    );
    addTearDown(playbackCubit.close);

    await tester.pumpWidget(localizedShell(
      MultiBlocProvider(
        providers: [
          BlocProvider<ReaderCubit>.value(value: cubit),
          BlocProvider<PlaybackCubit>.value(value: playbackCubit),
        ],
        child: const ReaderScreen(),
      ),
      textScaler: const TextScaler.linear(2.0),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('الم'), findsOneWidget);

    final semantics = tester.ensureSemantics();
    final glyphLabel = tester.getSemantics(find.text('﴿١﴾')).label;
    expect(glyphLabel, contains('الآية ١'));
    expect(glyphLabel, isNot(contains('﴿')),
        reason: 'the ornament must not survive into the semantics label');
    semantics.dispose();

    await tester.tap(find.byTooltip('وضع المصحف'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('صفحة'), findsOneWidget);

    await tester.tap(find.byTooltip('وضع الآيات'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_book_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final sheet = tester.widget<BottomSheet>(find.ancestor(
      of: find.text('تفسير الآية وترجمتها'),
      matching: find.byType(BottomSheet),
    ));
    expect(sheet.showDragHandle, isTrue);
    expect(find.text('تفسير الآية وترجمتها'), findsOneWidget);
    expect(find.text('لا يوجد تفسير مثبّت — نزّل من المكتبة'), findsOneWidget);
    expect(find.text('المكتبة'), findsOneWidget);
  });

  testWidgets(
      'textScale 2.0: bookmark rows keep the full snippet and the '
      'Arabic-Indic reference', (tester) async {
    const longText =
        'ذلك الكتاب لا ريب فيه هدى للمتقين الذين يؤمنون بالغيب ويقيمون الصلاة ومما رزقناهم ينفقون';
    final repo = _StaticBookmarksRepository(
      db,
      entries: const [
        BookmarkEntry(
          ayah: Ayah(
            id: 9,
            surahId: 2,
            numberInSurah: 9,
            juz: 1,
            page: 2,
            textUthmani: longText,
            textImlaei: longText,
            sajda: false,
          ),
        ),
      ],
    );

    await tester.pumpWidget(localizedShell(
      BlocProvider<BookmarksCubit>(
        create: (_) => BookmarksCubit(repo),
        child: const BookmarksScreen(),
      ),
      textScaler: const TextScaler.linear(2.0),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text(longText));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.textContaining('…'), findsNothing,
        reason: 'the snippet must not be hard-cut with a literal ellipsis');
    expect(find.text('٢:٩'), findsOneWidget);
  });
}
