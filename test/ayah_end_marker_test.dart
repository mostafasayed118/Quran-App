import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/domain/verse.dart';

void main() {
  group('stripAyahEndMarker', () {
    test('removes the trailing private-use end-of-ayah glyph', () {
      // 0xE95A is the HafsSmart verse-end medallion for ayah 1.
      expect(stripAyahEndMarker('abc\uE95A'), 'abc');
    });

    test('leaves text without a marker untouched', () {
      expect(stripAyahEndMarker('الم'), 'الم');
    });

    test('handles the empty string', () {
      expect(stripAyahEndMarker(''), '');
    });

    test('removes only the last glyph, never interior glyphs', () {
      expect(stripAyahEndMarker('\uE8DB \uE95A \uE95B'), '\uE8DB \uE95A');
    });

    test('strips the space + RLM separator that precedes the marker', () {
      expect(stripAyahEndMarker('الم \u200F\uE95A'), 'الم');
    });

    test('a marker-only string collapses to empty', () {
      expect(stripAyahEndMarker('\uE95A'), '');
    });
  });
}
