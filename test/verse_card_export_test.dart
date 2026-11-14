import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/verse_card.dart';

import 'support/host.dart';
import 'support/type_probe.dart';

/// Long enough to take the card's 18 px branch (over 400 characters) and to
/// stress the footer and the number line.
final _longVerse = Verse(
  id: 1,
  surahId: 2,
  numberInSurah: 255,
  juz: 3,
  page: 42,
  textUthmani: List.filled(60, 'آيَةٌ').join(' '),
  textImlaei: List.filled(60, 'آيَةٌ').join(' '),
  sajda: false,
  textUnicode: List.filled(60, 'آيَةٌ').join(' '),
);

void main() {
  testWidgets('the exported card is 720 px wide and loses no text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      appShell(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: VerseCard(
              ayah: _longVerse,
              surahName: 'سورة البقرة',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    addTearDown(image.dispose);

    expect(image.width, 720);
    expect(image.height, lessThan(2400));
    expectNotTruncated(tester, find.text(_longVerse.displayText));
  });
}
