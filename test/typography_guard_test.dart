import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';

/// Files that still carry a numeric `fontSize:` while this wave lands.
///
/// The list may only shrink: Task 2 removes the sub-11 entries, Task 3 the
/// five 1 px-adjacent values, and the final task leaves it empty.
const _exemptFiles = <String>{};

/// The off-ladder values those files still use. Shrinks with `_exemptFiles`.
final _offLadderValues = <double>{};

/// A bare literal only: computed sizes (`AppType.x * scale`) are not matches.
final _numericSize = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)\s*[,)]');
final _forbiddenWeight = RegExp(r'FontWeight\.w(?:500|600|800|900)\b');

List<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) =>
        !file.path.endsWith('.g.dart') && !file.path.endsWith('.freezed.dart'))
    .toList();

String _relative(File file) =>
    file.path.split(Platform.pathSeparator).join('/');

void main() {
  test('no numeric font size outside the theme', () {
    final offenders = <String>[];
    for (final file in _sources()) {
      final path = _relative(file);
      if (path.contains('/core/theme/') || _exemptFiles.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (_numericSize.hasMatch(lines[index])) {
          offenders.add('$path:${index + 1}: ${lines[index].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use AppType (or a named component token) instead of a number: '
          '${offenders.join(', ')}',
    );
  });

  test('every literal size is on the ladder or a known exception', () {
    final allowed = <double>{
      ...AppType.ladder,
      ...AppType.componentSizes,
      ..._offLadderValues,
    };
    final offenders = <String>[];
    for (final file in _sources()) {
      for (final match in _numericSize.allMatches(file.readAsStringSync())) {
        final value = double.parse(match.group(1)!);
        if (!allowed.contains(value)) {
          offenders.add('${_relative(file)}: $value');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Add a rung (with its role) before using a new size: '
          '${offenders.join(', ')}',
    );
  });

  test('the exempt list has no stale entries', () {
    final stale = _exemptFiles.where((path) {
      final file = File(path);
      return !file.existsSync() ||
          !_numericSize.hasMatch(file.readAsStringSync());
    }).toList();
    expect(stale, isEmpty, reason: 'Drop these from _exemptFiles: $stale');
  });

  test('only the two weights Cairo ships are requested', () {
    final offenders = _sources()
        .where((file) => _forbiddenWeight.hasMatch(file.readAsStringSync()))
        .map(_relative)
        .toList();
    expect(offenders, isEmpty);
  });

  test('no letter spacing inside a Quran-family style', () {
    final offenders = <String>[];
    for (final file in _sources()) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'TextStyle\(').allMatches(source)) {
        var depth = 0;
        var index = match.end - 1;
        while (index < source.length) {
          if (source[index] == '(') depth++;
          if (source[index] == ')') {
            depth--;
            if (depth == 0) break;
          }
          index++;
        }
        final block = source.substring(match.start, index + 1);
        final arabic = block.contains('QuranFonts.quran') ||
            block.contains('QuranFonts.meQuran');
        if (arabic && block.contains('letterSpacing')) {
          offenders.add(_relative(file));
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Tracking breaks Arabic joining.');
  });
}
