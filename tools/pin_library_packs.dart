// Pins the library catalog's floating CDN refs to immutable commit SHAs and
// (re)computes sha256 hashes for every artifact through its final pinned URL.
//
// Run: dart run tools/pin_library_packs.dart
//
// The catalog at assets/data/library_catalog.json is rewritten only after
// every artifact has been fetched and verified; on any failure the file is
// left untouched and the tool exits 1.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const _catalogPath = 'assets/data/library_catalog.json';

/// Repos whose `@1` ref is a floating branch that must be pinned. Neither
/// repo carries release tags, so the branch-head commit SHA is the only
/// immutable ref jsDelivr can serve (probe-verified 2026-10-18).
const _floatingRefs = <String>['quran-api', 'hadith-api'];

final _floatingPattern = RegExp('^https://cdn\\.jsdelivr\\.net/gh/fawazahmed0/'
    '(${_floatingRefs.join('|')})@1/');

final _sha40 = RegExp(r'^[0-9a-f]{40}$');

Future<void> main() async {
  final raw = File(_catalogPath).readAsStringSync();
  final root = jsonDecode(raw) as Map<String, dynamic>;
  final packs = (root['packs'] as List).cast<Map<String, dynamic>>();

  // Serializer fidelity: re-serializing the untouched catalog must reproduce
  // the original bytes exactly, so everything else this tool emits is
  // provably limited to the intended changes.
  final rebuilt = _serializeCatalog(root['catalogVersion'], packs);
  if (rebuilt != raw) {
    stderr.writeln('ABORT: catalog re-serialization is not byte-identical — '
        'refusing to rewrite.');
    exit(1);
  }

  // Phase 1: resolve every floating ref to a branch-head commit SHA.
  final resolved = <String, String>{};
  for (final repo in _floatingRefs) {
    final inUse = packs.any((p) => _urlOf(p).contains('fawazahmed0/$repo@1/'));
    if (!inUse) continue;
    final sha = await _resolveBranchHead(repo);
    resolved[repo] = sha;
    stdout.writeln('PINNED fawazahmed0/$repo@1 -> $sha');
  }

  // Phase 2: download every artifact through its final pinned URL, prove
  // floating-byte equivalence, and hash.
  final outPacks = <Map<String, dynamic>>[];
  for (var i = 0; i < packs.length; i++) {
    final pack = packs[i];
    final id = pack['id'] as String;
    final url = _urlOf(pack);
    final out = Map<String, dynamic>.of(pack);
    late final String ref;
    late final String report;

    if (pack['kind'] == 'tafsir') {
      final template = pack['urlTemplate'] as String;
      final count = pack['fileCount'] as int;
      final hashes = <String>[];
      var bytesTotal = 0;
      for (var n = 1; n <= count; n++) {
        final bytes =
            (await _fetch(Uri.parse(template.replaceFirst('{n}', '$n'))))
                .bodyBytes;
        bytesTotal += bytes.length;
        hashes.add(sha256.convert(bytes).toString());
        if (n % 20 == 0 || n == count) {
          stdout.writeln('  $id: $n/$count');
        }
      }
      out['sha256PerSurah'] = hashes;
      ref = pack['version'] as String;
      report = 'files=$count bytes=$bytesTotal hashes=$count';
    } else {
      final floatMatch = _floatingPattern.firstMatch(url);
      var finalUrl = url;
      if (floatMatch != null) {
        final sha = resolved[floatMatch.group(1)!]!;
        finalUrl = url.replaceFirst('@1/', '@$sha/');
        ref = sha;
      } else {
        ref = pack['version'] as String;
      }
      final bytes = (await _fetch(Uri.parse(finalUrl))).bodyBytes;
      if (floatMatch != null) {
        final viaFloatRef = (await _fetch(Uri.parse(url))).bodyBytes;
        if (sha256.convert(viaFloatRef).toString() !=
            sha256.convert(bytes).toString()) {
          stderr.writeln('ABORT: $id — bytes via @1 differ from the pinned '
              'ref; refusing to pin (CDN lag or the branch moved).');
          exit(1);
        }
        out['sourceUrl'] = finalUrl;
        out['version'] = ref;
      }
      out['sha256'] = sha256.convert(bytes).toString();
      report = 'files=1 bytes=${bytes.length}';
    }
    outPacks.add(out);
    stdout.writeln('[${i + 1}/${packs.length}] $id ref=$ref $report');
  }

  final emitted = _serializeCatalog(root['catalogVersion'], outPacks);
  if (emitted.contains('@1/')) {
    stderr.writeln('ABORT: emitted catalog still carries a floating @1 ref.');
    exit(1);
  }
  File(_catalogPath).writeAsStringSync(emitted);
  stdout.writeln('WROTE $_catalogPath (${emitted.length} bytes)');
}

String _urlOf(Map<String, dynamic> pack) =>
    (pack['sourceUrl'] ?? pack['urlTemplate']) as String;

String _serializeCatalog(
    Object? catalogVersion, List<Map<String, dynamic>> packs) {
  final parts = packs.map(_packJson).join(', ');
  return '{"catalogVersion": ${jsonEncode(catalogVersion)}, "packs": [$parts]}';
}

String _packJson(Map<String, dynamic> pack) =>
    '{${pack.entries.map((e) => '${jsonEncode(e.key)}: ${jsonEncode(e.value)}').join(', ')}}';

Future<String> _resolveBranchHead(String repo) async {
  final res = await _fetch(
    Uri.parse('https://api.github.com/repos/fawazahmed0/$repo/branches/1'),
    headers: {
      'User-Agent': 'quran-yahdi-pin-tool',
      'Accept': 'application/vnd.github+json',
    },
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  final sha = (decoded['commit'] as Map<String, dynamic>?)?['sha'];
  if (sha is! String || !_sha40.hasMatch(sha)) {
    stderr.writeln(
        'ABORT: cannot resolve fawazahmed0/$repo branch 1 to a commit SHA.');
    exit(1);
  }
  return sha;
}

/// One retry on transient failure, then fail-closed.
Future<http.Response> _fetch(Uri uri, {Map<String, String>? headers}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= 2; attempt++) {
    try {
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) return res;
      lastError = 'HTTP ${res.statusCode}';
    } on Object catch (e) {
      lastError = e;
    }
    if (attempt == 1) {
      stdout.writeln('RETRY once after failure ($lastError): $uri');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  stderr.writeln('ABORT: fetch failed twice for $uri — last error: $lastError');
  exit(1);
}
