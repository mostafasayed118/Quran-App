import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_source.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
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

class _FakeUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async =>
      {for (var i = 1; i <= 2; i++) i: 'آيَةٌ $i'};
}

class _Settings implements ReaderSettingsSource {
  _Settings(this.scale);

  double scale;

  @override
  Future<double> loadFontScale() async => scale;

  @override
  Future<void> saveFontScale(double value) async => scale = value;
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.batch((batch) => batch.insertAll(db.ayahs, [
          for (var i = 1; i <= 2; i++)
            AyahsCompanion.insert(
              id: Value(100 + i),
              surahId: 2,
              numberInSurah: i,
              juz: 1,
              page: 2,
              textUthmani: 'آيَةٌ $i',
              textImlaei: 'آيَةٌ $i',
            ),
        ]));
  });

  Future<void> pumpReader(
    WidgetTester tester, {
    required double fontScale,
    double textScale = 1.0,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final cubit = ReaderCubit(
      ayahRepository: _TeardownSafeAyahRepository(db),
      lastReadRepository: LastReadRepository(db),
      surahId: 2,
      initialAyah: 0,
      uthmani: _FakeUthmani(),
      settings: _Settings(fontScale),
    );
    addTearDown(cubit.close);
    await cubit.start();

    final playback = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db,
          audioRootResolver: () async => Directory.systemTemp),
    );
    addTearDown(playback.close);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<ReaderCubit>.value(value: cubit),
        BlocProvider<PlaybackCubit>.value(value: playback),
      ],
      child: appShell(home: const ReaderScreen(), textScale: textScale),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  Text badge(WidgetTester tester) => tester.widget<Text>(find.text('﴿١﴾'));

  testWidgets('the ayah number is 28 and follows the reader scale',
      (tester) async {
    await pumpReader(tester, fontScale: 1.0);
    expect(badge(tester).style?.fontSize, AppType.ayahNumber);
    expect(badge(tester).style?.fontFamily, AppTheme.ayahNumber.fontFamily);

    await pumpReader(tester, fontScale: 2.0);
    expect(badge(tester).style?.fontSize, AppType.ayahNumber * 2);
  });

  testWidgets('badge and four actions fit 320 dp at 2.0 x 2.0', (tester) async {
    await pumpReader(
      tester,
      fontScale: 2.0,
      textScale: 2.0,
      size: const Size(320, 800),
    );

    await tester.tap(find.text('آيَةٌ 1'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
    // The four actions are on screen (the app bar has its own IconButtons, so
    // count the action glyphs, not every IconButton).
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(badge(tester).style?.fontSize, AppType.ayahNumber * 2);
  });
}
