/// Audits `base..HEAD` for token substitutions and proves each one kept its
/// literal value.
///
/// The value test proves `token == shipped literal`; this tool proves the
/// **call site** got the token whose value equals the literal it replaced. It
/// pairs removed literals and added token references per hunk by role (alpha,
/// line height, tracking, opacity, icon, radius, stroke, hex), resolves each
/// token from `lib/core/theme/`, and fails on a mismatch or an unpaired change.
///
/// Usage: `dart run tool/design_token_diff_audit.dart [base-sha]`
///
/// The scan is textual, like `design_token_scan.dart`; an existing token that
/// was already on the removed line is not counted as a substitution, and a hunk
/// that mixes unrelated numbers is reported as unresolved instead of guessed.
library;

import 'dart:io';

const _defaultBase = '58dd3f95';

/// Hunk-local substitutions that cannot be paired textually.
///
/// `splash_screen.dart` removed the local `const card = Color(0xFF042C25);`
/// in one hunk and used `AppColors.splashCard` in another. The value test pins
/// the token, so the pair is recorded here rather than guessed from order.
const _manualPairs = <String, Map<String, String>>{
  'lib/app/splash_screen.dart': <String, String>{
    'AppColors.splashCard': '0xFF042C25',
  },
};

void main(List<String> args) {
  final base = args.isEmpty ? _defaultBase : args.first;
  final diff = Process.runSync(
    'git',
    <String>['diff', '-U0', base, '--', 'lib'],
    workingDirectory: Directory.current.path,
  ).stdout as String;

  final tokens = _loadTokens();
  final result = _audit(diff, tokens);

  stdout.writeln('base=$base head=worktree (clean == HEAD)');
  for (final line in result.lines) {
    stdout.writeln(line);
  }
  stdout.writeln(
    'pairs=${result.passed} failed=${result.failed} '
    'unresolved=${result.unresolved}',
  );
  if (result.failed > 0 || result.unresolved > 0) exitCode = 1;
}

_AuditResult _audit(String diff, Map<String, _TokenValue> tokens) {
  final lines = <String>[];
  var passed = 0;
  var failed = 0;
  var unresolved = 0;

  for (final file in _parseDiff(diff)) {
    if (file.path.contains('/core/theme/')) continue;
    final manual = _manualPairs[file.path] ?? const <String, String>{};

    for (final hunk in file.hunks) {
      final removedText = hunk.removed.join('\n');
      final literals = _literals(removedText);
      final refs = <_TokenRef>[
        for (final line in hunk.added) ..._tokenRefs(line.text, line.number),
      ];

      if (refs.isEmpty) {
        final manualValues =
            manual.values.map((value) => value.toUpperCase()).toSet();
        final unpaired = <String>[
          for (final hex in literals.hexes)
            if (!manualValues.contains(hex.toUpperCase())) 'hex $hex',
          for (final entry in literals.numbers.entries)
            for (final number in entry.value) '${entry.key} ${_fmt(number)}',
        ];
        if (unpaired.isNotEmpty) {
          lines.add(
            'UNRESOLVED ${file.path}:${hunk.newStart} '
            'removed ${unpaired.join(', ')} with no token',
          );
          unresolved++;
        }
        continue;
      }

      final used = <String, int>{
        for (final kind in _kinds) kind: 0,
        'bare': 0,
      };
      for (final ref in refs) {
        // A token that already existed on the removed line is unchanged, not a
        // substitution (e.g. fontSize: AppType.bodyLarge in the same style).
        if (removedText.contains(ref.name)) continue;

        final token = tokens[ref.name];
        final manualHex = manual[ref.name];
        if (token == null && manualHex == null) {
          lines.add(
            'UNRESOLVED ${file.path}:${ref.line} ${ref.name} (unknown token)',
          );
          unresolved++;
          continue;
        }

        final actualHex = token?.hex ?? manualHex;
        final actualNumber = token?.number;
        final kind = _kindOf(ref.name, literals, token);

        if (actualHex != null || kind == 'hex') {
          final old = _nextHex(literals, used);
          if (old == null) {
            if (manualHex != null) {
              lines.add(
                'PASS ${file.path}:${ref.line} '
                'manifest $manualHex -> ${ref.name} = $manualHex',
              );
              passed++;
            } else {
              lines.add(
                'UNRESOLVED ${file.path}:${ref.line} ${ref.name} '
                '(no removed hex to pair)',
              );
              unresolved++;
            }
            continue;
          }
          if (old.toUpperCase() == (actualHex ?? '').toUpperCase()) {
            lines.add(
              'PASS ${file.path}:${ref.line} $old -> ${ref.name} = $actualHex',
            );
            passed++;
          } else {
            lines.add(
              'FAIL ${file.path}:${ref.line} $old -> ${ref.name} = $actualHex',
            );
            failed++;
          }
          continue;
        }

        if (actualNumber == null) {
          lines.add(
            'UNRESOLVED ${file.path}:${ref.line} ${ref.name} (no value)',
          );
          unresolved++;
          continue;
        }
        final old = _nextNumber(literals, used, kind);
        if (old == null) {
          lines.add(
            'UNRESOLVED ${file.path}:${ref.line} ${ref.name} '
            '(no removed $kind to pair)',
          );
          unresolved++;
          continue;
        }
        if ((old - actualNumber).abs() < 1e-9) {
          lines.add(
            'PASS ${file.path}:${ref.line} ${_fmt(old)} -> '
            '${ref.name} = ${_fmt(actualNumber)}',
          );
          passed++;
        } else {
          lines.add(
            'FAIL ${file.path}:${ref.line} ${_fmt(old)} -> '
            '${ref.name} = ${_fmt(actualNumber)}',
          );
          failed++;
        }
      }

      final left = <String>[
        for (var index = used['hex']!; index < literals.hexes.length; index++)
          if (!manual.values
              .map((value) => value.toUpperCase())
              .contains(literals.hexes[index].toUpperCase()))
            'hex ${literals.hexes[index]}',
        for (final kind in _kinds.where((kind) => kind != 'hex'))
          for (var index = used[kind]!;
              index < literals.numbers[kind]!.length;
              index++)
            '$kind ${_fmt(literals.numbers[kind]![index])}',
      ];
      if (left.isNotEmpty) {
        lines.add(
          'UNRESOLVED ${file.path}:${hunk.newStart} '
          'removed ${left.join(', ')} not paired',
        );
        unresolved++;
      }
    }
  }

  return _AuditResult(
    lines: lines,
    passed: passed,
    failed: failed,
    unresolved: unresolved,
  );
}

const _kinds = <String>[
  'hex',
  'alpha',
  'opacity',
  'lineHeight',
  'tracking',
  'iconSize',
  'radius',
  'stroke',
];

String _kindOf(
  String name,
  _Literals literals,
  _TokenValue? token,
) {
  if (name.startsWith('AppAlphas.')) {
    return literals.numbers['opacity']!.isEmpty ? 'alpha' : 'opacity';
  }
  if (name.startsWith('AppType.')) {
    return name.endsWith('Tracking') ? 'tracking' : 'lineHeight';
  }
  if (name.startsWith('AppIconSize.')) return 'iconSize';
  if (name.startsWith('AppRadius.')) return 'radius';
  if (name.startsWith('AppStrokes.')) return 'stroke';
  if (name.startsWith('AppColors.')) {
    if (token?.hex != null) return 'hex';
    if (literals.numbers['alpha']!.isNotEmpty) return 'alpha';
    if (literals.numbers['opacity']!.isNotEmpty) return 'opacity';
    return 'bare';
  }
  return 'alpha';
}

String? _nextHex(_Literals literals, Map<String, int> used) {
  final index = used['hex']!;
  if (index >= literals.hexes.length) return null;
  used['hex'] = index + 1;
  return literals.hexes[index];
}

double? _nextNumber(
  _Literals literals,
  Map<String, int> used,
  String kind,
) {
  final queue = kind == 'bare' ? literals.bare : literals.numbers[kind]!;
  var index = used[kind]!;
  // `opacity: done ? 0.8 : 1` carries the identity 1 after the fade value.
  while (index < queue.length && kind == 'opacity' && queue[index] == 1) {
    index++;
  }
  if (index >= queue.length) {
    used[kind] = index;
    return null;
  }
  used[kind] = index + 1;
  return queue[index];
}

List<_DiffFile> _parseDiff(String diff) {
  final files = <_DiffFile>[];
  _DiffFile? file;
  _Hunk? hunk;
  var newLine = 0;
  final header = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@');
  final fileHeader = RegExp(r'^diff --git a/(.+) b/(.+)$');

  void closeHunk() {
    if (hunk != null) file!.hunks.add(hunk!);
    hunk = null;
  }

  for (final raw in diff.split('\n')) {
    final fileMatch = fileHeader.firstMatch(raw);
    if (fileMatch != null) {
      closeHunk();
      file = _DiffFile(fileMatch.group(2)!);
      files.add(file);
      continue;
    }
    final hunkMatch = header.firstMatch(raw);
    if (hunkMatch != null) {
      closeHunk();
      newLine = int.parse(hunkMatch.group(1)!);
      hunk = _Hunk(newStart: newLine);
      continue;
    }
    final current = hunk;
    if (current == null) continue;
    if (raw.startsWith('--- ') || raw.startsWith('+++ ')) continue;
    if (raw.startsWith('-')) {
      current.removed.add(raw.substring(1));
    } else if (raw.startsWith('+')) {
      current.added.add(_AddedLine(newLine, raw.substring(1)));
      newLine++;
    }
  }
  closeHunk();
  return files;
}

_Literals _literals(String text) {
  final numbers = <String, List<double>>{
    for (final kind in _kinds) kind: <double>[],
  };
  void collect(String kind, RegExp pattern) {
    for (final match in pattern.allMatches(text)) {
      for (final number in _bareNumber.allMatches(match.group(1)!)) {
        final value = double.parse(number.group(1)!);
        if (value == 0) continue;
        if (kind == 'opacity' && value == 1) continue;
        numbers[kind]!.add(value);
      }
    }
  }

  collect('alpha', RegExp(r'\balpha:\s*([^,\n)]*)'));
  collect('opacity', RegExp(r'\bopacity:\s*([^,\n)]*)'));
  collect('lineHeight', RegExp(r'\bheight:\s*([^,\n)]*)'));
  collect('tracking', RegExp(r'\bletterSpacing:\s*([^,\n)]*)'));
  collect('iconSize', RegExp(r'\bsize:\s*([^,\n)]*)'));
  collect('radius', RegExp(r'\bcircular\(\s*([^)]*)\)'));
  collect('stroke', RegExp(r'\bwidth:\s*([^,\n)]*)'));

  final hexes = RegExp(r'Color\(0x([0-9A-Fa-f]{6,8})\)')
      .allMatches(text)
      .map((match) => '0x${match.group(1)!.toUpperCase()}')
      .toList();
  final bare = _bareNumber
      .allMatches(text)
      .map((match) => double.parse(match.group(1)!))
      .where((value) => value != 0)
      .toList();

  return _Literals(numbers: numbers, hexes: hexes, bare: bare);
}

List<_TokenRef> _tokenRefs(String text, int line) => RegExp(
      r'App(Colors|Alphas|Type|IconSize|Radius|Strokes)\.([a-zA-Z0-9_]+)',
    )
        .allMatches(text)
        .map(
          (match) => _TokenRef(
            'App${match.group(1)!}.${match.group(2)!}',
            line,
          ),
        )
        .toList();

Map<String, _TokenValue> _loadTokens() {
  final out = <String, _TokenValue>{};
  const files = <String, String>{
    'AppColors': 'lib/core/theme/app_colors.dart',
    'AppAlphas': 'lib/core/theme/app_alphas.dart',
    'AppType': 'lib/core/theme/app_type.dart',
    'AppIconSize': 'lib/core/theme/app_icon_size.dart',
    'AppRadius': 'lib/core/theme/app_radius.dart',
    'AppStrokes': 'lib/core/theme/app_strokes.dart',
  };
  final declaration = RegExp(
    r'static const (?:double\s+|BorderRadius\s+)?([a-zA-Z0-9_]+)\s*=\s*([^;]+);',
  );

  for (final entry in files.entries) {
    final source = File(entry.value).readAsStringSync();
    for (final match in declaration.allMatches(source)) {
      final name = match.group(1)!;
      final value = match.group(2)!.trim();
      final hex = RegExp(r'Color\(0x([0-9A-Fa-f]{6,8})\)').firstMatch(value);
      if (hex != null) {
        out['${entry.key}.$name'] = _TokenValue(
          hex: '0x${hex.group(1)!.toUpperCase()}',
        );
      } else {
        final number = double.tryParse(value);
        if (number != null) {
          out['${entry.key}.$name'] = _TokenValue(number: number);
        }
      }
    }
  }

  final aliases = <String, String>{
    'AppType.quranMushaf': 'AppType.headline',
    'AppType.quranVerse': 'AppType.headlineLarge',
    'AppType.ayahNumber': 'AppType.stat',
  };
  for (final entry in aliases.entries) {
    final target = out[entry.value];
    if (target != null) out[entry.key] = target;
  }
  return out;
}

final _bareNumber = RegExp(
  r'(?<![\w.])(-?(?:\d+(?:\.\d+)?|\.\d+))(?![\w.])',
);

String _fmt(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

final class _AuditResult {
  const _AuditResult({
    required this.lines,
    required this.passed,
    required this.failed,
    required this.unresolved,
  });

  final List<String> lines;
  final int passed;
  final int failed;
  final int unresolved;
}

final class _DiffFile {
  _DiffFile(this.path);

  final String path;
  final List<_Hunk> hunks = <_Hunk>[];
}

final class _Hunk {
  _Hunk({required this.newStart});

  final int newStart;
  final List<String> removed = <String>[];
  final List<_AddedLine> added = <_AddedLine>[];
}

final class _AddedLine {
  const _AddedLine(this.number, this.text);

  final int number;
  final String text;
}

final class _TokenRef {
  const _TokenRef(this.name, this.line);

  final String name;
  final int line;
}

final class _TokenValue {
  const _TokenValue({this.number, this.hex});

  final double? number;
  final String? hex;
}

final class _Literals {
  const _Literals({
    required this.numbers,
    required this.hexes,
    required this.bare,
  });

  final Map<String, List<double>> numbers;
  final List<String> hexes;
  final List<double> bare;
}
