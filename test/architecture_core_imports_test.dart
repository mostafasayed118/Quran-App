import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final _directiveRe = RegExp(r"(?:import|export)\s+'([^']+)'");

/// Resolves an import/export target to a `lib/`-relative posix path; null for
/// non-local (dart:/foreign package) directives.
String? resolveLibTarget(String fileRel, String directive) {
  if (directive.startsWith('package:quran_yahdi/')) {
    return 'lib/${directive.substring('package:quran_yahdi/'.length)}';
  }
  if (directive.startsWith('dart:') || directive.startsWith('package:')) {
    return null;
  }
  if (!directive.startsWith('.')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fileRel), directive));
}

void main() {
  final sources = <String, String>{};
  for (final f
      in Directory('lib/core').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) {
      continue;
    }
    final rel = p.posix.joinAll(p.split(f.path)); // lib/... with / separators
    sources[rel] = f.readAsStringSync();
  }

  test('the scan actually reads the core tree', () {
    expect(sources.length, greaterThan(20));
  });

  test('resolver handles package, relative, and foreign directives', () {
    expect(
      resolveLibTarget(
          'lib/core/db/x.dart', 'package:quran_yahdi/core/domain/city.dart'),
      'lib/core/domain/city.dart',
    );
    expect(
      resolveLibTarget(
          'lib/core/widgets/x.dart', '../utils/arabic_numbers.dart'),
      'lib/core/utils/arabic_numbers.dart',
    );
    expect(resolveLibTarget('lib/core/db/x.dart', 'dart:io'), isNull);
    expect(
      resolveLibTarget('lib/core/db/x.dart', 'package:flutter/material.dart'),
      isNull,
    );
  });

  test('lib/core never imports or exports lib/features', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      for (final m in _directiveRe.allMatches(src)) {
        final target = resolveLibTarget(rel, m.group(1)!);
        if (target == null) continue;
        if (target == 'lib/features' || target.startsWith('lib/features/')) {
          offenders.add('$rel: ${m.group(0)}');
        }
      }
    });
    expect(
      offenders,
      isEmpty,
      reason: 'lib/core/ must not depend on lib/features/. Move the shared '
          'contract into lib/core/domain/ and inject the implementation from '
          'lib/app/di/. Offending directives:\n${offenders.join('\n')}',
    );
  });
}
