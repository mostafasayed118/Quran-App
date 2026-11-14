/// The residual-literal census behind `test/design_token_guard_test.dart`.
///
/// The scanner is deliberately textual: the repository has no analyzer plugin
/// intake, so a paren-balanced block walk is the strongest check available
/// without adding a dependency. It covers the three style constructors the
/// type system can produce (`TextStyle`, `StrutStyle`, `copyWith`) rather than
/// a single-line regex, which would miss every multi-line style in the tree.
///
/// It is a ratchet, not a proof: a computed value (`height: AppType.bodyHeight`)
/// is allowed, a literal is not.
library;

import 'dart:io';

/// One literal that should have been a token.
final class DesignTokenViolation {
  /// Creates a violation hit.
  const DesignTokenViolation({
    required this.file,
    required this.line,
    required this.kind,
    required this.value,
  });

  /// Posix-style path, e.g. `lib/app/splash_screen.dart`.
  final String file;

  /// One-based source line.
  final int line;

  /// `hex`, `alpha`, `lineHeight`, `tracking`, `opacity`, `iconSize`,
  /// `radius`, `stroke`.
  final String kind;

  /// Canonical literal, e.g. `0xFF042C25`, `0.1`, `1.8`, `18.0`.
  final String value;

  /// Stable grouping key used by the baseline map.
  String get key => '$file|$kind|$value';

  @override
  String toString() => '$file:$line ($kind $value)';
}

/// Scans every Dart source under `<root>/lib`.
List<DesignTokenViolation> scanLib([String? root]) {
  final package = Directory(root ?? Directory.current.path).absolute.path;
  final library = Directory('$package/lib');
  final files = library
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final out = <DesignTokenViolation>[];
  for (final file in files) {
    final path = _relative(file.absolute.path, package);
    if (path.contains('/core/theme/')) continue;
    out.addAll(scanSource(path, file.readAsStringSync()));
  }
  return out;
}

/// Counts hits by [DesignTokenViolation.key], sorted for a stable comparison.
Map<String, int> countViolations(Iterable<DesignTokenViolation> violations) {
  final counts = <String, int>{};
  for (final violation in violations) {
    counts[violation.key] = (counts[violation.key] ?? 0) + 1;
  }
  final keys = counts.keys.toList()..sort();
  return <String, int>{for (final key in keys) key: counts[key]!};
}

/// Scans one source text. [path] only labels the hits.
List<DesignTokenViolation> scanSource(String path, String source) {
  final out = <DesignTokenViolation>[];
  void add(int offset, String kind, String value) {
    out.add(
      DesignTokenViolation(
        file: path,
        line: _lineAt(source, offset),
        kind: kind,
        value: value,
      ),
    );
  }

  for (final match in _hex.allMatches(source)) {
    add(match.start, 'hex', '0x${match.group(1)!.toUpperCase()}');
  }

  for (final match in _alphaExpression.allMatches(source)) {
    final expression = match.group(1)!;
    final expressionOffset = match.start + match.group(0)!.indexOf(expression);
    for (final number in _bareNumber.allMatches(expression)) {
      final value = _number(number.group(1)!);
      // A zero alpha is a gradient stop (fully transparent end), not a role.
      if (value == 0) continue;
      add(expressionOffset + number.start, 'alpha', value.toString());
    }
  }

  for (final match in _tracking.allMatches(source)) {
    add(match.start, 'tracking', _number(match.group(1)!).toString());
  }

  for (final match in _opacityExpression.allMatches(source)) {
    final expression = match.group(1)!;
    final expressionOffset = match.start + match.group(0)!.indexOf(expression);
    for (final number in _bareNumber.allMatches(expression)) {
      final value = _number(number.group(1)!);
      // 1 is identity (no fade), not a design value.
      if (value == 1) continue;
      add(expressionOffset + number.start, 'opacity', value.toString());
    }
  }

  for (final start in _styleStarts(source)) {
    final block = _blockAt(source, start);
    for (final height in _lineHeight.allMatches(block)) {
      add(
        start + height.start,
        'lineHeight',
        _number(height.group(1)!).toString(),
      );
    }
  }

  for (final match in _iconStart.allMatches(source)) {
    final block = _blockAt(source, match.start);
    final size = _iconSize.firstMatch(block);
    if (size != null) {
      add(match.start + size.start, 'iconSize',
          _number(size.group(1)!).toString());
    }
  }

  for (final match in _radius.allMatches(source)) {
    add(match.start, 'radius', _number(match.group(1)!).toString());
  }

  for (final match in _borderStart.allMatches(source)) {
    final block = _blockAt(source, match.start);
    final width = _borderWidth.firstMatch(block);
    if (width != null) {
      add(match.start + width.start, 'stroke',
          _number(width.group(1)!).toString());
    }
  }

  out.sort((a, b) {
    final byLine = a.line.compareTo(b.line);
    if (byLine != 0) return byLine;
    final byKind = a.kind.compareTo(b.kind);
    return byKind != 0 ? byKind : a.value.compareTo(b.value);
  });
  return out;
}

final _hex = RegExp(r'Color\(0x([0-9A-Fa-f]{6,8})\)');
final _alphaExpression = RegExp(r'withValues\(\s*alpha:\s*([^)]*)\)');
final _bareNumber = RegExp(
  r'(?<![\w.])(-?(?:\d+(?:\.\d+)?|\.\d+))(?![\w.])',
);
final _tracking = RegExp(
  r'\bletterSpacing:\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\s*[,)]',
);
final _opacityExpression = RegExp(r'\bopacity:\s*([^)]*)\)');
final _lineHeight = RegExp(
  r'\bheight:\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\s*[,)]',
);
final _iconStart = RegExp(r'\bIcon\(');
final _iconSize = RegExp(
  r'\bsize:\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\s*[,)]',
);
final _radius = RegExp(
  r'\b(?:BorderRadius|Radius)\.circular\(\s*(-?\d+(?:\.\d+)?)\s*\)',
);
final _borderStart = RegExp(r'\b(?:BorderSide|Border\.all)\(');
final _borderWidth = RegExp(
  r'\bwidth:\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\s*[,)]',
);

/// Offsets where a text-style block opens.
Iterable<int> _styleStarts(String source) sync* {
  for (final match
      in RegExp(r'\b(?:TextStyle|StrutStyle)\(').allMatches(source)) {
    yield match.start;
  }
  // `copyWith` is the only other constructor that can carry a line height;
  // state copyWith calls never declare `height` in this tree, and the baseline
  // test below proves the detector sees a synthetic one.
  for (final match in RegExp(r'\.copyWith\(').allMatches(source)) {
    yield match.start;
  }
}

String _blockAt(String source, int from) {
  final open = source.indexOf('(', from);
  if (open < 0) return '';
  var depth = 0;
  for (var index = open; index < source.length; index++) {
    final unit = source.codeUnitAt(index);
    if (unit == 0x28) {
      depth++;
    } else if (unit == 0x29) {
      depth--;
      if (depth == 0) return source.substring(open, index + 1);
    }
  }
  return source.substring(open);
}

double _number(String text) => double.parse(text);

int _lineAt(String source, int offset) {
  var line = 1;
  for (var index = 0; index < offset && index < source.length; index++) {
    if (source.codeUnitAt(index) == 0x0A) line++;
  }
  return line;
}

String _posix(String path) => path.replaceAll(Platform.pathSeparator, '/');

String _relative(String absolute, String package) {
  final path = _posix(absolute);
  final base = _posix(package);
  return path.startsWith('$base/') ? path.substring(base.length + 1) : path;
}
