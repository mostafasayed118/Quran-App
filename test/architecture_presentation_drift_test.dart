import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The only `presentation/` files allowed to read the drift layer directly.
///
/// Both are frozen-test compatibility shims: their public symbols are called
/// **only from `test/`**, and moving them out of `presentation/` would change
/// an import path a frozen test pins. Pinning the current set means a THIRD
/// one is a deliberate architecture decision, not a silent drift — which is
/// what the existing guard's rules cannot express for `lib/core/db/`.
const Set<String> allowedPresentationDriftReaders = {
  'lib/features/quran/presentation/reader/mushaf_page_block_rows.dart',
  'lib/features/recitation/presentation/playback/playback_row_entry.dart',
};

final _importRe = RegExp(r"(?:import|export)\s+'([^']+)'");

String? _resolve(String fileRel, String import) {
  if (import.startsWith('package:quran_yahdi/')) {
    return 'lib/${import.substring('package:quran_yahdi/'.length)}';
  }
  if (import.startsWith('dart:') || import.startsWith('package:')) return null;
  if (!import.startsWith('.')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fileRel), import));
}

String? _layerOf(String libRel) {
  final match = RegExp(r'^lib/features/[a-z_]+/([a-z_]+)/').firstMatch(libRel);
  return match?.group(1);
}

void main() {
  test('presentation reads the drift layer only through the pinned shims', () {
    final readers = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final rel = p.posix.joinAll(p.split(entity.path));
      if (_layerOf(rel) != 'presentation') continue;
      for (final match in _importRe.allMatches(entity.readAsStringSync())) {
        final target = _resolve(rel, match.group(1)!);
        if (target == null) continue;
        if (target.startsWith('lib/core/db/')) readers.add(rel);
      }
    }

    expect(readers, allowedPresentationDriftReaders,
        reason: 'a presentation file must not read drift rows directly — go '
            'through the feature\'s data/ layer. The two pinned files are '
            'frozen-test compatibility shims; a third needs its own ruling.');
  });

  test('the scan actually reads the tree', () {
    final count = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .length;
    expect(count, greaterThan(100));
  });
}
