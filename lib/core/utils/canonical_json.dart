import 'dart:convert';

/// A deterministic JSON encoding: object keys are sorted at every level, so
/// two sides that hold the same values always produce the same bytes.
///
/// This is what makes a byte-level check safe in two places:
/// - the backup envelope authenticates its header as AES-GCM AAD, where a
///   different key order would silently fail the tag check;
/// - the version policy is signed over its own document, where the signature
///   must survive a re-serialization that reorders keys.
String canonicalJson(Object? value) {
  if (value is Map) {
    final keys = [for (final key in value.keys) '$key']..sort();
    final buffer = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write(',');
      buffer
        ..write(jsonEncode(keys[i]))
        ..write(':')
        ..write(canonicalJson(value[keys[i]]));
    }
    buffer.write('}');
    return buffer.toString();
  }
  if (value is List) {
    return '[${value.map(canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}
