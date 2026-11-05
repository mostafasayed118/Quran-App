import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/verse_card.dart';
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

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('the card renders the verse, surah name and attribution',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const VerseCard(
      ayah: _verse,
      surahName: 'الفاتحة',
    )));

    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('quran yahdi'), findsOneWidget);
    expect(find.textContaining('quranyahdi'), findsOneWidget);
  });

  testWidgets('the card falls back to the glyph text without Unicode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const glyphOnly = Verse(
      id: 2,
      surahId: 2,
      numberInSurah: 2,
      juz: 1,
      page: 2,
      textUthmani: 'ذلك الكتاب',
      textImlaei: 'ذلك الكتاب',
      sajda: false,
    );

    await tester.pumpWidget(_app(const VerseCard(
      ayah: glyphOnly,
      surahName: 'البقرة',
    )));

    expect(find.text('ذلك الكتاب'), findsOneWidget);
  });

  testWidgets(
      'the card survives a 320-wide surface without horizontal overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const SingleChildScrollView(
      child: VerseCard(ayah: _verse, surahName: 'الفاتحة', width: 300),
    )));

    expect(tester.takeException(), isNull);
  });
}
