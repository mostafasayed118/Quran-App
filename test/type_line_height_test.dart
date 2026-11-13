import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';

void main() {
  final text = AppTheme.light.textTheme;

  test('the smallest role keeps a 1.4 line box', () {
    expect(text.labelSmall?.height, greaterThanOrEqualTo(1.4));
    expect(text.bodySmall?.height, greaterThanOrEqualTo(1.4));
    expect(AppTheme.sectionLabel.height, greaterThanOrEqualTo(1.4));
  });

  test('the body roles keep at least 1.5', () {
    expect(text.bodyLarge?.height, greaterThanOrEqualTo(1.5));
    expect(text.bodyMedium?.height, greaterThanOrEqualTo(1.5));
    expect(AppTheme.caption.height, greaterThanOrEqualTo(1.5));
    expect(AppTheme.bodyText.height, greaterThanOrEqualTo(1.5));
  });

  test('display roles keep at least 1.15', () {
    expect(AppTheme.heroValue.height, greaterThanOrEqualTo(1.15));
    expect(AppTheme.heroTitle.height, greaterThanOrEqualTo(1.15));
    expect(AppTheme.cardTitle.height, greaterThanOrEqualTo(1.15));
  });

  test('no role falls under the 1.35 sanity floor', () {
    final heights = <String, double?>{
      'headlineMedium': text.headlineMedium?.height,
      'headlineSmall': text.headlineSmall?.height,
      'titleLarge': text.titleLarge?.height,
      'titleMedium': text.titleMedium?.height,
      'titleSmall': text.titleSmall?.height,
      'bodyLarge': text.bodyLarge?.height,
      'bodyMedium': text.bodyMedium?.height,
      'bodySmall': text.bodySmall?.height,
      'labelLarge': text.labelLarge?.height,
      'labelMedium': text.labelMedium?.height,
      'labelSmall': text.labelSmall?.height,
    };
    for (final entry in heights.entries) {
      if (entry.value != null) {
        expect(entry.value, greaterThanOrEqualTo(1.35), reason: entry.key);
      }
    }
  });

  test('the Quran line box stays 2.0', () {
    expect(AppTheme.hafsAyah.height, AppType.quranHeight);
    expect(AppType.quranHeight, 2.0);
  });
}
