import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
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
  late AyahRepository repo;
  late LastReadRepository lastRead;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final baqarah = [
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
    ];
    final fatiha = [
      AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'بسم الله الرحمن الرحيم',
          textImlaei: 'بسم الله الرحمن الرحيم'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, baqarah));
    await db.batch((b) => b.insertAll(db.ayahs, fatiha));
    lastRead = LastReadRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget host(int surahId) {
    repo = _TeardownSafeAyahRepository(db);
    final cubit = ReaderCubit(
        ayahRepository: repo,
        lastReadRepository: lastRead,
        surahId: surahId,
        initialAyah: 0);
    final playbackCubit = PlaybackCubit(
      service: _FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db,
          audioRootResolver: () async => Directory.systemTemp),
    );
    addTearDown(playbackCubit.close);
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReaderCubit>.value(value: cubit),
        BlocProvider<PlaybackCubit>.value(value: playbackCubit),
      ],
      child: const ReaderScreen(),
    );
  }

  testWidgets('surah 2 shows basmala banner and ayah cards in verse mode',
      (tester) async {
    final screen = host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('بسم الله الرحمن الرحيم'), findsNothing,
        reason: 'Fatiha text is not part of surah 2');
  });

  testWidgets('bookmark heart toggles the DB row', (tester) async {
    final screen = host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    final rows = await db.select(db.bookmarks).get();
    expect(rows, hasLength(1));
    expect(rows.single.ayahId, 8);
  });

  testWidgets('mushaf mode renders page blocks with the page indicator',
      (tester) async {
    final screen = host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('وضع المصحف'));
    await tester.pumpAndSettle();

    expect(find.textContaining('صفحة'), findsOneWidget);
  });
}
