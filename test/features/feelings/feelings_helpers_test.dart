import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/core/utils/arabic_date.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_icons.dart';

void main() {
  test('Arabic date uses Arabic month names and Indic digits', () {
    expect(formatArabicDate(DateTime(2026, 11, 26)), '٢٦ نوفمبر ٢٠٢٦');
  });

  test('all feeling icons resolve to Material icons', () {
    for (final name in [
      'air',
      'water_drop',
      'person_pin_circle',
      'explore',
      'shield',
      'whatshot',
      'sunny',
      'auto_awesome',
    ]) {
      expect(feelingIcon(name), isA<IconData>());
    }
    expect(feelingIcon('air'), Icons.air);
    expect(feelingIcon('whatshot'), Icons.whatshot);
  });

  test('route helpers encode query parameters', () {
    expect(feelingsVersesPath('qalaq'), '/feelings/verses?feeling=qalaq');
    expect(
      feelingsVersePath(13, 28, 'qalaq'),
      '/feelings/verse?surah=13&ayah=28&feeling=qalaq',
    );
  });
}
