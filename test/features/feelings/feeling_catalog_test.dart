import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final source = AssetUthmaniTextSource(rootBundle);

  test('eight feelings in the specified order with exactly two verses', () {
    expect(FeelingsCatalog.ordered.map((f) => f.key.value).toList(), [
      'qalaq',
      'huzn',
      'wahda',
      'hayra',
      'khawf',
      'ghadab',
      'imtinam',
      'amal',
    ]);
    for (final feeling in FeelingsCatalog.ordered) {
      expect(feeling.verses, hasLength(2), reason: feeling.key.value);
      expect(feeling.iconName, isNotEmpty);
    }
  });

  test('all 16 excerpts are exact substrings of their Uthmani ayah', () async {
    for (final feeling in FeelingsCatalog.ordered) {
      for (final verse in feeling.verses) {
        final ayahs = await source.forSurah(verse.surah);
        final full = ayahs[verse.ayah];
        expect(full, isNotNull, reason: '${verse.reference} missing in asset');
        expect(
          full,
          contains(verse.excerpt),
          reason: 'excerpt of ${verse.reference} is not a source substring',
        );
      }
    }
  });

  test('hero excerpt is the trailing part of Ar-Ra\'d 28', () async {
    final ayahs = await source.forSurah(13);
    final full = ayahs[28]!;
    expect(full, contains(FeelingsCatalog.heroExcerpt));
    expect(full.endsWith(FeelingsCatalog.heroExcerpt), isTrue);
  });

  test('invalid feeling keys are rejected', () {
    expect(FeelingKey.fromValue('nope'), isNull);
    expect(FeelingKey.fromValue(null), isNull);
    expect(FeelingKey.fromValue('qalaq'), FeelingKey.qalaq);
  });
}
