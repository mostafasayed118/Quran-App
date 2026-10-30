import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ has no print/debugPrint and no obvious secret logging', () {
    final forbidden = RegExp(r'\b(print|debugPrint)\s*\(');
    final secret = RegExp(
      r'(password|secret|authorization|bearer|api[_-]?key|access[_-]?token)',
      caseSensitive: false,
    );
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) =>
            file.path.endsWith('.dart') &&
            !file.path.endsWith('.g.dart') &&
            !file.path.endsWith('.freezed.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (forbidden.hasMatch(line)) {
          fail('${file.path}:${i + 1} uses print/debugPrint');
        }
        if (!line.contains('dev.log(')) continue;
        // The call's arguments may span several lines; check the whole call
        // window for names that imply a credential or session token.
        final window = lines.skip(i).take(8).join('\n');
        if (secret.hasMatch(window)) {
          fail('${file.path}:${i + 1} logs a secret-like value');
        }
      }
    }
  });
}
