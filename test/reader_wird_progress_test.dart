import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/wird_progress_sink.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _RecordingSink implements WirdProgressSink {
  final ids = <int>[];

  @override
  Future<void> advanceTo(int ayahId) async => ids.add(ayahId);
}

class _ThrowingSink implements WirdProgressSink {
  @override
  Future<void> advanceTo(int ayahId) async => throw StateError('sink down');
}

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

/// Bounded settles: drift futures + page-snap animations advance on explicit
/// pumps only (no pumpAndSettle, per the wave brief).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late AyahRepository ayahs;
  late LastReadRepository lastRead;

  setUp(() async {
    db = newTestDb();
    final fatiha = [
      AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'بسم الله',
          textImlaei: 'بسم الله'),
    ];
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
    await db.batch((b) => b.insertAll(db.ayahs, fatiha));
    await db.batch((b) => b.insertAll(db.ayahs, baqarah));
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 3,
              pagesStart: 2,
              pagesEnd: 3),
        );
    ayahs = AyahRepository(db);
    lastRead = LastReadRepository(db);
  });

  test('mushaf page changes advance the sink with the page-first ayah',
      () async {
    final sink = _RecordingSink();
    final cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0,
        wirdProgress: sink);
    final readyFuture = cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.start();
    await readyFuture;

    await cubit.onMushafPageChanged(0);
    await cubit.onMushafPageChanged(1);
    await cubit.onMushafPageChanged(7); // out of range: ignored

    expect(sink.ids, [8, 10]);
    await cubit.close();
  });

  test('without a sink the page change still persists last-read', () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0);
    final readyFuture = cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.start();
    await readyFuture;

    await cubit.onMushafPageChanged(0);

    expect(await lastRead.loadAyahId(), 8);
    await cubit.close();
  });

  test('a throwing sink is swallowed and last-read survives', () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0,
        wirdProgress: _ThrowingSink());
    final readyFuture = cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.start();
    await readyFuture;

    await cubit.onMushafPageChanged(0);

    expect(await lastRead.loadAyahId(), 8);
    await cubit.close();
  });

  testWidgets('mushaf paging forwards the page-first ayah to the sink',
      (tester) async {
    final sink = _RecordingSink();
    final repo = _TeardownSafeAyahRepository(db);
    final cubit = ReaderCubit(
        ayahRepository: repo,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0,
        wirdProgress: sink);
    addTearDown(cubit.close);
    await cubit.start();
    final playbackCubit = PlaybackCubit(
      service: _FakePlaybackService(),
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
        home: const ReaderScreen(),
      ),
    ));
    await settle(tester);

    await tester.tap(find.byTooltip('وضع المصحف'));
    await settle(tester);
    expect(find.byType(PageView), findsOneWidget);

    // RTL paging: dragging the content rightward reveals the next page.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await settle(tester);

    expect(sink.ids, contains(10));
  });
}
