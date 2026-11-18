import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RED for L-3: the declared `environment.sdk` constraint must be resolvable
/// by the SDK that produced pubspec.lock. It was `^3.5.0` while the lock
/// requires Dart >=3.13.0, so a clean checkout on the minimum declared SDK
/// cannot resolve dependencies. The fix raises the constraint to `^3.13.0`.
void main() {
  test('declared SDK constraint covers the locked SDK requirement', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();

    // The declared floor must be at least the lock's Dart floor.
    final declared = RegExp(r'^\s*sdk:\s*\^(\d+\.\d+)', multiLine: true)
        .firstMatch(pubspec)
        ?.group(1);
    final locked = RegExp(r'dart:\s*">=(\d+\.\d+)').firstMatch(lock)?.group(1);

    expect(declared, isNotNull, reason: 'no sdk constraint in pubspec.yaml');
    expect(locked, isNotNull, reason: 'no dart floor in pubspec.lock');
    final declaredParts = declared!.split('.').map(int.parse).toList();
    final lockedParts = locked!.split('.').map(int.parse).toList();
    final declaredAtLeastLocked = declaredParts[0] > lockedParts[0] ||
        (declaredParts[0] == lockedParts[0] &&
            declaredParts[1] >= lockedParts[1]);
    expect(declaredAtLeastLocked, isTrue,
        reason:
            'declared sdk ^$declared is below the lock requirement >=$locked');
  });
}
