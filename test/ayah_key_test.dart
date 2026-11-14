import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/ayah_key.dart';

void main() {
  test('round-trips every surah and every ayah up to al-Baqarah', () {
    for (var surah = 1; surah <= 114; surah++) {
      for (var ayah = 0; ayah <= 286; ayah++) {
        final key = AyahKey.encode(surah, ayah);
        expect(AyahKey.surahOf(key), surah, reason: 'surah $surah/$ayah');
        expect(AyahKey.ayahOf(key), ayah, reason: 'ayah $surah/$ayah');
      }
    }
  });

  test('pins the shipped wire values', () {
    expect(AyahKey.encode(1, 1), 1001);
    expect(AyahKey.encode(2, 255), 2255);
    expect(AyahKey.encode(114, 6), 114006);
  });

  test('keeps the legacy edge values total', () {
    final zeroAyah = AyahKey.encode(114, 0);
    expect(zeroAyah, 114000);
    expect(AyahKey.surahOf(zeroAyah), 114);
    expect(AyahKey.ayahOf(zeroAyah), 0);
    expect(AyahKey.encode(0, 0), 0);
    expect(AyahKey.surahOf(0), 0);
    expect(AyahKey.ayahOf(0), 0);
  });

  test('negative input keeps the old operator behavior', () {
    // The inline code was `key ~/ 1000` and `key % 1000`; these pins keep a
    // future validation change from silently throwing at the pack boundary.
    expect(AyahKey.surahOf(-1), 0);
    expect(AyahKey.ayahOf(-1), 999);
    expect(AyahKey.encode(-1, 5), -995);
  });
}
