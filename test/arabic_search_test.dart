import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/arabic_search.dart';

void main() {
  group('normalizeArabic', () {
    test('strips tashkeel and the superscript alef', () {
      expect(normalizeArabic('الرَّحْمَٰن'), 'الرحمن');
    });

    test('strips tatweel', () {
      expect(normalizeArabic('الـرحـمن'), 'الرحمن');
    });

    test('folds alef variants to plain alef', () {
      expect(normalizeArabic('إسلام آمن أَخ ٱلْحَمْدُ'), 'اسلام امن اخ الحمد');
    });

    test('folds alef maqsura to ya', () {
      expect(normalizeArabic('مُوسَى'), 'موسي');
    });

    test('folds ta marbuta to ha', () {
      expect(normalizeArabic('رَحْمَة'), 'رحمه');
    });

    test('folds hamza seats to their seat letters', () {
      expect(normalizeArabic('مَسْؤُول بِئْر'), 'مسوول بير');
    });

    test('collapses whitespace and trims', () {
      expect(normalizeArabic('  اللَّهُ   الرَّحْمَٰن '), 'الله الرحمن');
    });

    test('leaves already-plain text untouched', () {
      expect(
          normalizeArabic('بسم الله الرحمن الرحيم'), 'بسم الله الرحمن الرحيم');
    });
  });

  group('matchesQuery', () {
    test('diacritic-heavy text matches a plain query', () {
      expect(matchesQuery('الرَّحْمَٰنُ الرَّحِيمُ', 'الرحمن'), isTrue);
      expect(matchesQuery('ذِكْرُ الصَّبَاحِ وَالْمَسَاءِ', 'الصباح'), isTrue);
    });

    test('hamza and ta-marbuta variants match both ways', () {
      expect(matchesQuery('مَسْؤُول', 'مسوول'), isTrue);
      expect(matchesQuery('رحمة الله', 'رحمه الله'), isTrue);
      expect(matchesQuery('إِنَّ الْإِسْلَامَ دِينُنَا', 'الاسلام'), isTrue);
    });

    test('substring matches inside longer text', () {
      expect(matchesQuery('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ', 'إلا'), isTrue);
    });

    test('an empty or whitespace query matches everything', () {
      expect(matchesQuery('أي نص', ''), isTrue);
      expect(matchesQuery('أي نص', '   '), isTrue);
    });

    test('latin matching ignores case', () {
      expect(matchesQuery('Morning remembrance', 'MORNING'), isTrue);
      expect(matchesQuery('Morning remembrance', 'evening'), isFalse);
    });

    test('unrelated queries do not match', () {
      expect(matchesQuery('أذكار الصباح', 'النوم'), isFalse);
    });
  });
}
