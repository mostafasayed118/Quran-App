import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/pack_reader.dart';

/// The production read path (no injected decoder) decodes + projects inside a
/// worker isolate: the returned values must match the injected-decoder path
/// exactly, prove the in-isolate index builder, and keep the absent semantics.
void main() {
  late Directory tempDir;
  late Map<String, String> paths;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('qy_pack_reader_iso');
    final translation = {
      'quran': [
        {'chapter': 1, 'verse': 1, 'text': 'T1:1'},
        {'chapter': 2, 'verse': 255, 'text': 'T2:255'},
        {'chapter': 3, 'verse': 4, 'text': ''},
        {'chapter': 3, 'verse': 5, 'text': 'T3:5'},
      ],
    };
    final tafsir = {
      'pack': 'tf',
      'tafsirs': [
        {'surah': 1, 'ayah': 1, 'text': 'X1:1'},
        {'surah': 112, 'ayah': 2, 'text': 'X112:2'},
      ],
    };
    final hadith = {
      'hadiths': [
        {'hadithnumber': 1, 'text': 'H1'},
        {'hadithnumber': 'bad', 'text': 'skipped'},
        {'hadithnumber': 2, 'text': 'H2'},
      ],
    };
    paths = {
      'tr': '${tempDir.path}/tr.json',
      'tf': '${tempDir.path}/tf.json',
      'hd': '${tempDir.path}/hd.json',
      'corrupt': '${tempDir.path}/corrupt.json',
      'wrong-shape': '${tempDir.path}/wrong-shape.json',
    };
    File(paths['tr']!).writeAsStringSync(jsonEncode(translation));
    File(paths['tf']!).writeAsStringSync(jsonEncode(tafsir));
    File(paths['hd']!).writeAsStringSync(jsonEncode(hadith));
    File(paths['corrupt']!).writeAsStringSync('not json at all {');
    File(paths['wrong-shape']!).writeAsStringSync('[1,2,3]');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  PackReader productionReader() =>
      PackReader(packPath: (packId) async => paths[packId]);

  PackReader injectedReader() => PackReader(
        fileDecoder: (path) async => jsonDecode(File(path).readAsStringSync()),
        packPath: (packId) async => paths[packId],
      );

  test('production isolate path serves translation, tafsir and hadith windows',
      () async {
    final reader = productionReader();

    expect(await reader.translationFor('tr', 1, 1), 'T1:1');
    expect(await reader.translationFor('tr', 2, 255), 'T2:255');
    expect(await reader.translationFor('tr', 3, 4), isNull); // empty text
    expect(await reader.translationFor('tr', 3, 5), 'T3:5');
    expect(await reader.translationFor('tr', 114, 6), isNull);

    expect(await reader.tafsirFor('tf', 1, 1), 'X1:1');
    expect(await reader.tafsirFor('tf', 112, 2), 'X112:2');
    expect(await reader.tafsirFor('tf', 2, 1), isNull);

    final firstPage = await reader.hadithPage('hd', 0, 2);
    expect(firstPage.$1, [(1, 'H1')]);
    expect(firstPage.$2, isTrue); // the malformed entry still consumes a slot

    final lastPage = await reader.hadithPage('hd', 2, 2);
    expect(lastPage.$1, [(2, 'H2')]);
    expect(lastPage.$2, isFalse);

    final beyond = await reader.hadithPage('hd', 9, 2);
    expect(beyond.$1, isEmpty);
    expect(beyond.$2, isFalse);
  });

  test('absent, corrupt and non-object files read as absent', () async {
    final reader = productionReader();

    expect(await reader.translationFor('missing', 1, 1), isNull);
    expect(await reader.tafsirFor('missing', 1, 1), isNull);
    final absent = await reader.hadithPage('missing', 0, 2);
    expect(absent.$1, isEmpty);
    expect(absent.$2, isFalse);

    expect(await reader.translationFor('corrupt', 1, 1), isNull);
    expect(await reader.tafsirFor('corrupt', 1, 1), isNull);

    expect(await reader.translationFor('wrong-shape', 1, 1), isNull);
    expect(await reader.tafsirFor('wrong-shape', 1, 1), isNull);
    expect((await reader.hadithPage('wrong-shape', 0, 2)).$1, isEmpty);
  });

  test('production and injected-decoder paths return identical results',
      () async {
    final production = productionReader();
    final injected = injectedReader();

    for (final query in <(String, int, int)>[
      ('tr', 1, 1),
      ('tr', 2, 255),
      ('tr', 114, 6),
      ('tf', 1, 1),
      ('tf', 112, 2),
    ]) {
      final (packId, surah, ayah) = query;
      final fromProduction = packId == 'tr'
          ? await production.translationFor(packId, surah, ayah)
          : await production.tafsirFor(packId, surah, ayah);
      final fromInjected = packId == 'tr'
          ? await injected.translationFor(packId, surah, ayah)
          : await injected.tafsirFor(packId, surah, ayah);
      expect(fromProduction, fromInjected, reason: '$query must agree');
    }

    // Records compare their fields with `==`, so compare the paged lists
    // structurally and the flags directly.
    for (final window in <(int, int)>[(0, 1), (1, 9)]) {
      final (offset, limit) = window;
      final fromProduction = await production.hadithPage('hd', offset, limit);
      final fromInjected = await injected.hadithPage('hd', offset, limit);
      expect(fromProduction.$1, fromInjected.$1, reason: '$window items');
      expect(fromProduction.$2, fromInjected.$2, reason: '$window hasMore');
    }
  });

  test('a cached value of the wrong shape behaves like an absent cache entry',
      () async {
    final reader = injectedReader();
    // Poison the pack's cache slot with a hadith-shaped list, then read it as
    // a translation pack: the read must recover via the cold path, not throw.
    reader.primeList('tr', <dynamic>['not', 'an', 'index']);

    expect(await reader.translationFor('tr', 1, 1), 'T1:1');
  });
}
