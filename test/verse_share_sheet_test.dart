import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/data/ayah_sharer.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/verse_share_sheet.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

const _verse = Verse(
  id: 1,
  surahId: 1,
  numberInSurah: 1,
  juz: 1,
  page: 1,
  textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  textImlaei: 'بسم الله الرحمن الرحيم',
  sajda: false,
  textUnicode: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
);

class _FakeSharer implements AyahSharer {
  int textCalls = 0;
  int imageCalls = 0;
  String? lastText;
  Uint8List? lastImage;
  String? lastFileName;

  @override
  Future<void> shareText(String text) async {
    textCalls += 1;
    lastText = text;
  }

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    required String text,
  }) async {
    imageCalls += 1;
    lastImage = bytes;
    lastFileName = fileName;
    lastText = text;
  }
}

Widget _app({
  required _FakeSharer sharer,
  required VerseImageCapture? capture,
  double? textScale,
}) =>
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: textScale == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showVerseShareSheet(
              context,
              ayah: _verse,
              surahName: 'الفاتحة',
              sharer: sharer,
              capture: capture,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

Future<void> _openSheet(
  WidgetTester tester, {
  required _FakeSharer sharer,
  required VerseImageCapture? capture,
  double? textScale,
}) async {
  await tester.pumpWidget(
    _app(sharer: sharer, capture: capture, textScale: textScale),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the image action shares the captured PNG and the text',
      (tester) async {
    final sharer = _FakeSharer();
    final png = Uint8List.fromList(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    await _openSheet(
      tester,
      sharer: sharer,
      capture: (_) async => png,
    );

    await tester.tap(find.text('مشاركة كصورة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sharer.imageCalls, 1);
    expect(sharer.lastImage, png);
    expect(sharer.lastFileName, 'ayah-1-1.png');
    expect(sharer.lastText, contains('بِسْمِ اللَّهِ'));
    expect(sharer.lastText, contains('quranyahdi'));
  });

  testWidgets('a failed capture falls back to the text share', (tester) async {
    final sharer = _FakeSharer();
    await _openSheet(
      tester,
      sharer: sharer,
      capture: (_) async => null,
    );

    await tester.tap(find.text('مشاركة كصورة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sharer.imageCalls, 0);
    expect(sharer.textCalls, 1);
    expect(sharer.lastText, contains('quranyahdi'));
  });

  testWidgets('a throwing capture still shares the text', (tester) async {
    final sharer = _FakeSharer();
    await _openSheet(
      tester,
      sharer: sharer,
      capture: (_) async => throw StateError('raster failed'),
    );

    await tester.tap(find.text('مشاركة كصورة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sharer.imageCalls, 0);
    expect(sharer.textCalls, 1);
  });

  testWidgets('the text action shares without an image', (tester) async {
    final sharer = _FakeSharer();
    await _openSheet(tester, sharer: sharer, capture: null);

    await tester.tap(find.text('مشاركة كنص'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sharer.textCalls, 1);
    expect(sharer.imageCalls, 0);
  });

  testWidgets('the real capture emits a PNG signature', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sharer = _FakeSharer();
    await _openSheet(tester, sharer: sharer, capture: null);

    await tester.tap(find.text('مشاركة كصورة'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(sharer.imageCalls, 1);
    final bytes = sharer.lastImage;
    expect(bytes, isNotNull);
    expect(bytes!.take(4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('320 dp at textScale 2.0 keeps the actions above the inset',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    await _openSheet(
      tester,
      sharer: _FakeSharer(),
      capture: (_) async => null,
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('مشاركة كصورة'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final action = tester.getRect(find.text('مشاركة كصورة'));
    expect(action.bottom, lessThanOrEqualTo(640 - 48));
  });
}
