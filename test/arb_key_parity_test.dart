import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards AR/EN ARB key parity (440 keys at the time of writing).
///
/// A string added to one locale but not the other silently falls back at
/// runtime (or shows the raw key), so a missing mirror is a user-visible
/// defect. This is a strict set-equality pin: adding a key requires an AR+EN
/// pair. It is intentionally NOT registered as a Class B inventory pin — the
/// set only grows in locked pairs, so additions keep the test green.
void main() {
  Map<String, dynamic> readArb(String path) {
    // The ARB files carry a UTF-8 BOM; strip it before decoding.
    final raw = File(path).readAsStringSync();
    final json = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  test('AR and EN ARBs expose the same message keys', () {
    final ar = readArb('lib/l10n/app_ar.arb');
    final en = readArb('lib/l10n/app_en.arb');
    final arKeys = ar.keys.where((k) => !k.startsWith('@')).toSet();
    final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();

    expect(arKeys.difference(enKeys), isEmpty,
        reason: 'AR keys missing from EN: ${arKeys.difference(enKeys)}');
    expect(enKeys.difference(arKeys), isEmpty,
        reason: 'EN keys missing from AR: ${enKeys.difference(arKeys)}');
  });
}
