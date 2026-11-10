import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/l10n/app_localizations_ar.dart';
import 'package:quran_yahdi/l10n/app_localizations_en.dart';

void main() {
  group('qibla degree copy', () {
    final ar = AppLocalizationsAr();

    test('Arabic spells out the degree word so the digits keep their order',
        () {
      expect(ar.degreesFromNorth('١٣٦'), '١٣٦ درجة عن الشمال');
      expect(ar.degreesFromNorth('١٣٦'), isNot(contains('°')));
    });

    test('both turn directions use the same degree word', () {
      expect(ar.qiblaTurnRight('١٣٦'), 'أدر الهاتف ١٣٦ درجة يمينًا');
      expect(ar.qiblaTurnLeft('٤٥'), 'أدر الهاتف ٤٥ درجة يسارًا');
    });

    test('English keeps the conventional degree sign', () {
      final en = AppLocalizationsEn();
      expect(en.degreesFromNorth('136'), '136° from north');
    });
  });
}
