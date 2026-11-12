import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/fake_playback_service.dart';
import 'support/host.dart';
import 'support/test_db.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

/// Fails the first ayah read with a StateError, then reads normally —
/// the transient-failure shape the retry button exists for.
class _FlakyAyahRepository extends _TeardownSafeAyahRepository {
  _FlakyAyahRepository(super.db);
  bool failNext = true;

  @override
  Future<List<Ayah>> surahAyahs(int surahId) {
    if (failNext) {
      failNext = false;
      return Future.error(StateError('db busy'));
    }
    return super.surahAyahs(surahId);
  }
}

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;

  setUp(() {
    db = newTestDb();
    lastRead = LastReadRepository(db);
  });

  test('a surah with no readable ayahs emits ReaderError, not a blank ready',
      () async {
    final cubit = ReaderCubit(
      ayahRepository: _TeardownSafeAyahRepository(db),
      lastReadRepository: lastRead,
      surahId: 999,
      initialAyah: 0,
    );
    addTearDown(cubit.close);

    final failureFuture = cubit.stream.firstWhere((s) => s is ReaderError);
    await cubit.start();
    final failure = await failureFuture as ReaderError;
    expect(failure.message, isNotEmpty);
    expect(await lastRead.loadAyahId(), isNull,
        reason: 'an unreadable surah must not overwrite last-read');
  });

  test('reload recovers once the data reads again', () async {
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
        ]));
    final cubit = ReaderCubit(
      ayahRepository: _FlakyAyahRepository(db),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);

    final failureFuture = cubit.stream.firstWhere((s) => s is ReaderError);
    await cubit.start();
    await failureFuture;
    await cubit.reload();
    expect(cubit.state, isA<ReaderReady>());
  });

  testWidgets('the error state is titled and retriable; retry recovers',
      (tester) async {
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
        ]));
    final cubit = ReaderCubit(
      ayahRepository: _FlakyAyahRepository(db),
      lastReadRepository: lastRead,
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

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
    expect(find.text('أعِد المحاولة'), findsOneWidget);

    await tester.tap(find.text('أعِد المحاولة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('أعِد المحاولة'), findsNothing);
    expect(find.text('الم'), findsOneWidget);
  });
}
