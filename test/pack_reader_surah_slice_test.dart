import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/pack_reader.dart';

/// Single-surah read path: the projection keeps only the requested surah, each
/// surah gets its own cache slot, and invalidation clears every slice.
void main() {
  test('buildAyahIndex keeps only the requested surah', () {
    final index = PackReader.buildAyahIndex([
      {'chapter': 1, 'verse': 1, 'text': 'a'},
      {'surah': 2, 'ayah': 3, 'text': 'b'},
      {'chapter': 1, 'verse': 2, 'text': 'c'},
    ], surah: 1);

    expect(index, {1001: 'a', 1002: 'c'});
  });

  test('each surah slice decodes once and serves only its own surah', () async {
    var calls = 0;
    final reader = PackReader(
      fileDecoder: (path) async {
        calls++;
        return {
          'tafsirs': [
            {'surah': 1, 'ayah': 1, 'text': 'one'},
            {'surah': 2, 'ayah': 1, 'text': 'two'},
          ],
        };
      },
      packPath: (packId) async => '/fake/$packId.json',
    );

    expect(await reader.tafsirFor('tf', 1, 1), 'one');
    expect(await reader.tafsirFor('tf', 2, 1), 'two');
    expect(await reader.tafsirFor('tf', 1, 1), 'one');
    expect(await reader.tafsirFor('tf', 1, 2), isNull);
    expect(calls, 2);
  });

  test('invalidate drops the pack slice too', () async {
    var text = 'OLD';
    var calls = 0;
    final reader = PackReader(
      fileDecoder: (path) async {
        calls++;
        return {
          'quran': [
            {'chapter': 1, 'verse': 1, 'text': text},
          ],
        };
      },
      packPath: (packId) async => '/fake/$packId.json',
    );

    expect(await reader.translationFor('tr', 1, 1), 'OLD');
    text = 'NEW';
    reader.invalidate('tr');
    expect(await reader.translationFor('tr', 1, 1), 'NEW');
    expect(calls, 2);
  });
}
