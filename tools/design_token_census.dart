/// Prints the residual-literal census for the token wave.
///
/// Usage:
///   dart run tool/design_token_census.dart            # Dart baseline map
///   dart run tool/design_token_census.dart --sites    # every hit
///   dart run tool/design_token_census.dart --md       # markdown table
library;

import 'dart:io';

import 'design_token_scan.dart';

void main(List<String> args) {
  final violations = scanLib();
  final counts = countViolations(violations);

  if (args.contains('--sites')) {
    for (final violation in violations) {
      stdout.writeln(violation);
    }
    return;
  }

  if (args.contains('--md')) {
    stdout.writeln('| file | line | kind | value |');
    stdout.writeln('|---|---|---|---|');
    for (final violation in violations) {
      stdout.writeln(
        '| `${violation.file}` | ${violation.line} | ${violation.kind} | '
        '`${violation.value}` |',
      );
    }
    return;
  }

  stdout.writeln(
    '// ${violations.length} residual literals in ${counts.length} buckets.',
  );
  stdout.writeln('const Map<String, int> designTokenBaseline = <String, int>{');
  for (final entry in counts.entries) {
    stdout.writeln("  '${entry.key}': ${entry.value},");
  }
  stdout.writeln('};');
}
