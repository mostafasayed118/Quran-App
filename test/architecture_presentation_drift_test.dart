import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// No `presentation/` file may read the drift layer directly.
///
/// The set is empty on purpose. It used to hold two frozen-test
/// compatibility shims (`mushaf_page_block_rows`, `playback_row_entry`);
/// both now live in their feature's `data/` layer and are re-exported from the
/// same public path the frozen tests import, so the presentation layer is
/// drift-free while the tests keep compiling.
const Set<String> allowedPresentationDriftReaders = <String>{};

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
