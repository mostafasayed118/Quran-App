import 'dart:io';

import 'package:drift/drift.dart' show Value;
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

import 'support/test_db.dart';

/// The bookmark stream never closes on its own; the value stream keeps the
/// reader's teardown clean while the toggle still writes through the real
/// repository.
class _QuietBookmarks extends AyahRepository {
  _QuietBookmarks(super.db);

  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

class _ThrowingToggle extends AyahRepository {
  _ThrowingToggle(super.db);

  @override
  Future<void> toggleBookmark(int ayahId) async {
    throw StateError('bookmark write failed');
  }
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
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the bookmark confirms that the verse was saved',
      (tester) async {
    await pumpReader(tester);

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    expect(find.text('تم حفظ الآية'), findsOneWidget);

    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('a failed bookmark write reports false instead of throwing', () async {
    final cubit = ReaderCubit(
      ayahRepository: _ThrowingToggle(db),
      lastReadRepository: LastReadRepository(db),
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);

    expect(await cubit.toggleBookmark(101), isFalse);
  });
}
