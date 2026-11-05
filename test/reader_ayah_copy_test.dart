import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_playback_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

/// Unicode Uthmani text that is deliberately distinguishable from the imlaei
/// column, so a test can prove which one reached the clipboard.
class _FakeUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async =>
      {for (var i = 1; i <= 12; i++) i: 'آيَةٌ $i'};
}

/// Private-use codepoints are how the bundled Hafs font encodes glyphs; they
/// are meaningless in any other app.
final _pua = RegExp('[\uE000-\uF8FF]');

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;

  setUp(() async {
    db = newTestDb();
    await db.batch((b) => b.insertAll(db.ayahs, [
          for (var i = 1; i <= 12; i++)
            AyahsCompanion.insert(
              id: Value(100 + i),
              surahId: 2,
              numberInSurah: i,
              juz: 1,
              page: i <= 6 ? 2 : 3,
              // The real asset stores a private-use encoding here; imlaei is
              // the plain orthography.
              textUthmani: '\u200F\uE8DB \u200F\uE338',
              textImlaei: 'آية $i',
            ),
        ]));
    lastRead = LastReadRepository(db);
  });

  Future<void> pumpReader(
    WidgetTester tester, {
    bool unicode = true,
  }) async {
    final cubit = ReaderCubit(
      ayahRepository: _TeardownSafeAyahRepository(db),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 0,
      uthmani: unicode ? _FakeUthmani() : null,
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

  List<MethodCall> captureClipboard(WidgetTester tester) {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return calls;
  }

  testWidgets('with Unicode text the reader renders it and allows selection',
      (tester) async {
    await pumpReader(tester);

    expect(find.byType(SelectionArea), findsOneWidget);
    final ayah = tester.widget<Text>(find.text('آيَةٌ 1'));
    expect(ayah.style?.fontFamily, AppTheme.hafsAyah.fontFamily);
  });

  testWidgets('copy takes the Unicode Uthmani text, never the glyph column',
      (tester) async {
    await pumpReader(tester);
    final clipboard = captureClipboard(tester);

    await tester.tap(find.byIcon(Icons.copy_outlined).first);
    await tester.pumpAndSettle();

    expect(clipboard, hasLength(1));
    final text = (clipboard.single.arguments as Map)['text'] as String;
    expect(text, 'آيَةٌ 1');
    expect(_pua.hasMatch(text), isFalse);
    expect(find.text('تم نسخ الآية'), findsOneWidget);
  });

  testWidgets('with Unicode text a long-press starts selection, not copy',
      (tester) async {
    await pumpReader(tester);
    final clipboard = captureClipboard(tester);

    await tester.longPress(find.text('آيَةٌ 1'));
    await tester.pumpAndSettle();

    // SelectionArea owns the gesture; the copy shortcut only exists for the
    // glyph fallback where selection would be meaningless.
    expect(clipboard, isEmpty);
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('the glyph fallback still copies on long-press', (tester) async {
    await pumpReader(tester, unicode: false);
    final clipboard = captureClipboard(tester);

    await tester.longPress(find.textContaining('\uE8DB').first);
    await tester.pumpAndSettle();

    expect(clipboard, hasLength(1));
    final text = (clipboard.single.arguments as Map)['text'] as String;
    expect(text, 'آية 1');
    expect(_pua.hasMatch(text), isFalse);
  });

  testWidgets(
      'without the asset it falls back to glyphs, no selection, and '
      'copies the imlaei column', (tester) async {
    await pumpReader(tester, unicode: false);

    expect(find.byType(SelectionArea), findsNothing);
    final ayah = tester.widget<Text>(find.textContaining('\uE8DB').first);
    expect(ayah.style?.fontFamily, AppTheme.hafsAyah.fontFamily);

    final clipboard = captureClipboard(tester);
    await tester.tap(find.byIcon(Icons.copy_outlined).first);
    await tester.pumpAndSettle();

    final text = (clipboard.single.arguments as Map)['text'] as String;
    expect(text, 'آية 1');
    expect(_pua.hasMatch(text), isFalse);
  });

  testWidgets('a vertical drag still scrolls the list', (tester) async {
    await pumpReader(tester);
    final list = tester.state<ScrollableState>(find
        .descendant(
          of: find.byType(ScrollablePositionedList),
          matching: find.byType(Scrollable),
        )
        .first);
    final before = list.position.pixels;

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(list.position.pixels, greaterThan(before + 100));
  });

  testWidgets('mushaf mode: a horizontal fling still turns the page',
      (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byTooltip('وضع المصحف'));
    await tester.pumpAndSettle();

    String pageLabel() =>
        tester.widget<Text>(find.textContaining('صفحة')).data!;
    expect(pageLabel(), contains('٢'));

    final rtl = Directionality.of(tester.element(find.byType(PageView))) ==
        TextDirection.rtl;
    await tester.fling(
      find.byType(PageView),
      Offset(rtl ? 600 : -600, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(pageLabel(), contains('٣'));
  });
}
