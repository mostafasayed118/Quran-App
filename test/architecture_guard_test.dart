import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Pinned cross-feature edges — every entry is a DELIBERATE dependency.
/// Adding an edge here is an architecture decision; do not grow silently.
/// PM ruling 2026-10-19: three pre-existing edges ratified after the guard's first run.
const Set<String> allowedFeatureEdges = {
  'home->prayer',
  'home->quran',
  'duas->quran',
  'quran->recitation',
  'quran->library',
  'qibla->prayer',
  'prayer->notifications',
  'settings->notifications',
  'notifications->prayer',
  'notifications->tracker',
  'settings->prayer',
};

final _importRe = RegExp(r"(?:import|export)\s+'([^']+)'");

/// Resolves an import target to a `lib/`-relative posix path; null for
/// non-local (dart:/foreign package) imports.
String? resolveTarget(String fileRel, String import) {
  if (import.startsWith('package:quran_yahdi/')) {
    return 'lib/${import.substring('package:quran_yahdi/'.length)}';
  }
  if (import.startsWith('dart:') || import.startsWith('package:')) return null;
  if (!import.startsWith('.')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fileRel), import));
}

String? featureOf(String libRel) =>
    RegExp(r'^lib/features/([a-z_]+)/').firstMatch(libRel)?.group(1);

(String, String)? edgeOf(String fromRel, String toRel) {
  final from = featureOf(fromRel);
  final to = featureOf(toRel);
  if (from == null || to == null || from == to) return null;
  return (from, to);
}

void main() {
  final sources = <String, String>{};
  for (final f
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) {
      continue;
    }
    final rel = p.posix.joinAll(p.split(f.path)); // lib/... with / separators
    sources[rel] = f.readAsStringSync();
  }

  test('the scan actually reads the tree', () {
    expect(sources.length, greaterThan(100));
  });

  test('resolver handles package, relative, and foreign imports', () {
    expect(
        resolveTarget('lib/features/a/x.dart',
            'package:quran_yahdi/core/db/app_database.dart'),
        'lib/core/db/app_database.dart');
    expect(
        resolveTarget(
            'lib/features/a/presentation/x.dart', '../../../core/utils/a.dart'),
        'lib/core/utils/a.dart');
    expect(resolveTarget('lib/features/a/x.dart', 'dart:async'), isNull);
    expect(
        resolveTarget('lib/features/a/x.dart', 'package:flutter/material.dart'),
        isNull);
  });

  test('no feature imports the app layer', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/features/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = resolveTarget(rel, m.group(1)!);
        if (target != null && target.startsWith('lib/app/')) {
          offenders.add('$rel -> ${m.group(1)}');
        }
      }
    });
    expect(offenders, isEmpty,
        reason:
            'features must not depend on lib/app/ — move shared logic to core/');
  });

  test('cross-feature edges stay within the pinned allowlist', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/features/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = resolveTarget(rel, m.group(1)!);
        if (target == null) continue;
        final edge = edgeOf(rel, target);
        if (edge == null) continue;
        if (!allowedFeatureEdges.contains('${edge.$1}->${edge.$2}')) {
          offenders.add('$rel -> ${m.group(1)} [${edge.$1}->${edge.$2}]');
        }
      }
    });
    expect(offenders, isEmpty,
        reason: 'new cross-feature dependency — add it to allowedFeatureEdges '
            'consciously in this test, or remove the import');
  });

  test('feature data layers stay Flutter-free', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!RegExp(r'^lib/features/[a-z_]+/data/').hasMatch(rel)) return;
      if (_importRe
          .allMatches(src)
          .any((m) => m.group(1) == 'package:flutter/material.dart')) {
        offenders.add(rel);
      }
    });
    expect(offenders, isEmpty,
        reason: 'data-layer files must not import flutter/material');
  });
}
