import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/deep_links.dart';

void main() {
  const host = 'https://quranyahdi.pages.dev';
  Uri link(String path) => Uri.parse('$host$path');

  group('deepLinkRouteFor — §3 mapping table', () {
    test('/surah/{n} → reader at that surah', () {
      expect(deepLinkRouteFor(link('/surah/36')), '/quran/reader?surah=36');
      expect(deepLinkRouteFor(link('/surah/1')), '/quran/reader?surah=1');
      expect(deepLinkRouteFor(link('/surah/114')), '/quran/reader?surah=114');
    });

    test('#ayah-{m} (m >= 1) → reader at surah + ayah', () {
      expect(deepLinkRouteFor(link('/surah/36#ayah-1')),
          '/quran/reader?surah=36&ayah=1');
      expect(deepLinkRouteFor(link('/surah/2#ayah-255')),
          '/quran/reader?surah=2&ayah=255');
    });

    test('invalid surah number (0, 115, non-numeric) → null', () {
      expect(deepLinkRouteFor(link('/surah/0')), isNull);
      expect(deepLinkRouteFor(link('/surah/115')), isNull);
      expect(deepLinkRouteFor(link('/surah/abc')), isNull);
    });

    test('trailing slash tolerated', () {
      expect(deepLinkRouteFor(link('/surah/36/')), '/quran/reader?surah=36');
      expect(deepLinkRouteFor(link('/surah/36/#ayah-5')),
          '/quran/reader?surah=36&ayah=5');
    });

    test('absent/invalid fragment → surah-only route', () {
      expect(deepLinkRouteFor(link('/surah/36')), '/quran/reader?surah=36');
      expect(
          deepLinkRouteFor(link('/surah/36#ayah-0')), '/quran/reader?surah=36');
      expect(deepLinkRouteFor(link('/surah/36#x')), '/quran/reader?surah=36');
    });

    test('/quran → quran index', () {
      expect(deepLinkRouteFor(link('/quran')), '/quran');
      expect(deepLinkRouteFor(link('/quran/')), '/quran');
    });

    test('/reciters → recitation', () {
      expect(deepLinkRouteFor(link('/reciters')), '/recitation');
      expect(deepLinkRouteFor(link('/reciters/')), '/recitation');
    });

    test('anything else → null', () {
      expect(deepLinkRouteFor(link('/')), isNull);
      expect(deepLinkRouteFor(link('/about')), isNull);
      expect(deepLinkRouteFor(link('/surah')), isNull);
    });

    test('wrong host or scheme → null', () {
      expect(
          deepLinkRouteFor(Uri.parse('https://example.com/surah/36')), isNull);
      expect(
          deepLinkRouteFor(Uri.parse('http://quranyahdi.pages.dev/surah/36')),
          isNull);
    });
  });

  group('webSurahUrl — exact web parity (byte-for-byte with urls.ts)', () {
    test('surah only', () {
      expect(webSurahUrl(36), 'https://quranyahdi.pages.dev/surah/36');
    });

    test('with ayah fragment', () {
      expect(
          webSurahUrl(36, 5), 'https://quranyahdi.pages.dev/surah/36#ayah-5');
    });
  });
}
