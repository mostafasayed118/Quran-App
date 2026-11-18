import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RED for L-11: extend the Semantics pass to five features that had no
/// Semantics widget (reader, bookmarks, settings, zakat, duas). Source-scan
/// follows the repo's a11y/log-hygiene convention; before the fix these dirs
/// contain no Semantics, after the fix each has at least one meaningful label.
void main() {
  const dirs = <String>{
    'lib/features/quran/presentation/reader',
    'lib/features/quran/presentation/bookmarks',
    'lib/features/settings/presentation',
    'lib/features/zakat/presentation',
    'lib/features/duas/presentation',
  };

  test('reader/bookmarks/settings/zakat/duas use Semantics labels', () {
    for (final dir in dirs) {
      final files = Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.dart') && !f.path.endsWith('.freezed.dart'))
          .toList();
      final withSemantics = files.where(
        (f) => f.readAsStringSync().contains('Semantics('),
      );
      expect(withSemantics, isNotEmpty,
          reason: '$dir has no Semantics widget for screen readers');
    }
  });
}
