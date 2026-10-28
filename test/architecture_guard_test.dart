import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The EXACT set of permitted direct feature->feature imports.
///
/// A new edge is an architecture decision (PM ruling): add it here on purpose —
/// never let this set grow to match the tree. Reconciled 2026-10-28, pruning
/// the 9 dead permissions that had accumulated since the 2026-10-19 first run;
/// the pinned set below is what `lib/` actually contains.
const Set<String> allowedFeatureEdges = {
  'quran->library',
  'quran->recitation',
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

const Set<String> _layers = {'presentation', 'data', 'domain', 'playback'};

/// The segment after the feature name when it names a layer directory
/// (`presentation`, `data`, `domain`, `playback`); null otherwise.
String? layerOf(String libRel) {
  final feature = featureOf(libRel);
  if (feature == null) return null;
  final rest = libRel.substring('lib/features/$feature/'.length);
  final segment = rest.split('/').first;
  return _layers.contains(segment) ? segment : null;
}

/// A local import resolved to `lib/`-relative posix paths.
typedef ResolvedImport = ({String from, String target, String import});

/// Every local import in [sources] whose target resolves inside `lib/`.
List<ResolvedImport> resolvedImports(Map<String, String> sources) => [
      for (final entry in sources.entries)
        for (final match in _importRe.allMatches(entry.value))
          if (resolveTarget(entry.key, match.group(1)!) case final target?)
            (from: entry.key, target: target, import: match.group(1)!),
    ];

/// `lib/core/**` must never import into `lib/features/`.
List<String> coreToFeatureViolations(Map<String, String> sources) => [
      for (final i in resolvedImports(sources))
        if (i.from.startsWith('lib/core/') &&
            i.target.startsWith('lib/features/'))
          '${i.from} -> ${i.import}',
    ];

/// A feature's `presentation/` must never import another feature's `data/`.
///
/// The feature-level allowlist above cannot express this: agreeing to
/// `quran->library` (a presentation widget) must not silently license
/// `quran/presentation/` reaching into `library/data/`. No allowlist here —
/// there are no such hops today, and a legitimate one would need its own ruling.
List<String> presentationDataHops(Map<String, String> sources) => [
      for (final i in resolvedImports(sources))
        if (layerOf(i.from) == 'presentation' &&
            layerOf(i.target) == 'data' &&
            featureOf(i.from) != featureOf(i.target))
          '${i.from} -> ${i.import}',
    ];

/// Live cross-feature `from->to` edges found in [sources].
Set<String> liveFeatureEdges(Map<String, String> sources) {
  final edges = <String>{};
  for (final i in resolvedImports(sources)) {
    final edge = edgeOf(i.from, i.target);
    if (edge != null) edges.add('${edge.$1}->${edge.$2}');
  }
  return edges;
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

  test('core never imports a feature', () {
    expect(coreToFeatureViolations(sources), isEmpty,
        reason: 'lib/core/ must not depend on lib/features/ — a cross-feature '
            'need goes through a port in lib/core/domain/');
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

  test('allowedFeatureEdges is exactly the live edge set', () {
    final live = liveFeatureEdges(sources);
    final missing = live.difference(allowedFeatureEdges).toList()..sort();
    final dead = allowedFeatureEdges.difference(live).toList()..sort();
    expect(allowedFeatureEdges, live,
        reason: 'allowedFeatureEdges is the EXACT set of permitted '
            'feature->feature edges. Unpinned live edges: $missing. '
            'Dead permissions to delete: $dead. A new edge is an architecture '
            'decision — edit this test deliberately.');
  });

  test('presentation never imports another feature\'s data', () {
    expect(presentationDataHops(sources), isEmpty,
        reason: 'a feature\'s presentation/ must not reach into another '
            'feature\'s data/ — go through that feature\'s domain or a '
            'lib/core/domain/ port');
  });

  test('the new detectors catch planted violations', () {
    const planted = <String, String>{
      'lib/core/utils/planted.dart':
          "import '../../features/quran/domain/planted.dart';",
      'lib/features/quran/presentation/planted.dart':
          "import '../../library/data/planted.dart';",
      'lib/features/library/data/planted.dart': '',
      'lib/features/quran/domain/planted.dart': '',
    };
    expect(coreToFeatureViolations(planted), hasLength(1));
    expect(presentationDataHops(planted), hasLength(1));
    expect(liveFeatureEdges(planted), {'quran->library'});
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
