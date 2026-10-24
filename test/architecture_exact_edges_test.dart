import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Exact dependency pins that complement `architecture_guard_test.dart`.
///
/// The guard's allowlist is deliberately permissive (a superset of the live
/// edges), so a new edge between two already-listed features could pass
/// silently. These tests pin the live set instead, and assert the one rule
/// the guard does not cover: `lib/core` never imports a feature.

final _importRe = RegExp(r"(?:import|export)\s+'([^']+)'");

String? _resolveTarget(String fileRel, String import) {
  if (import.startsWith('package:quran_yahdi/')) {
    return 'lib/${import.substring('package:quran_yahdi/'.length)}';
  }
  if (import.startsWith('dart:') || import.startsWith('package:')) return null;
  if (!import.startsWith('.')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fileRel), import));
}

String? _featureOf(String libRel) =>
    RegExp(r'^lib/features/([a-z_]+)/').firstMatch(libRel)?.group(1);

(String, String)? _edgeOf(String fromRel, String toRel) {
  final from = _featureOf(fromRel);
  final to = _featureOf(toRel);
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
    sources[p.posix.joinAll(p.split(f.path))] = f.readAsStringSync();
  }

  test('the scan reads the hand-written tree', () {
    expect(sources.length, greaterThan(100));
  });

  test('lib/core never imports a feature', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/core/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = _resolveTarget(rel, m.group(1)!);
        if (target != null && target.startsWith('lib/features/')) {
          offenders.add('$rel -> ${m.group(1)}');
        }
      }
    });
    expect(offenders, isEmpty,
        reason: 'core must stay feature-agnostic (dependency direction: '
            'app -> features -> core)');
  });

  test('the live cross-feature edges are exactly the ratified three', () {
    final live = <String>{};
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/features/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = _resolveTarget(rel, m.group(1)!);
        if (target == null) continue;
        final edge = _edgeOf(rel, target);
        if (edge != null) live.add('${edge.$1}->${edge.$2}');
      }
    });
    expect(live, {'quran->library', 'quran->recitation'},
        reason: 'a new feature-to-feature dependency needs a conscious '
            'architecture decision; keep this set exact');
  });
}
