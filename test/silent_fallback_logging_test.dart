import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RED for L-7: four read paths swallow decode/parse errors with a bare
/// `on Object { return null/empty; }` and log nothing, so a corrupt local value
/// silently looks like empty state. The fix keeps the fail-open behaviour but
/// adds an appLog(...) in each fallback. This source-scan test follows the
/// repo's log-hygiene pattern (a release build cannot observe dev.log), and
/// asserts each fallback file now routes the failure through appLog.
void main() {
  const fallbacks = <String>{
    'lib/features/tasbih/data/tasbih_repository.dart',
    'lib/features/library/data/hadith_bookmark_repository.dart',
    'lib/core/utils/city_clock.dart',
    'lib/features/backup/data/backup_io.dart',
  };

  test('each silent fail-open fallback logs through appLog', () {
    for (final rel in fallbacks) {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: '$rel missing');
      final source = file.readAsStringSync();
      expect(
        source.contains('appLog('),
        isTrue,
        reason: '$rel swallows a decode/parse error without appLog',
      );
    }
  });
}
