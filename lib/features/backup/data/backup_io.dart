import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'backup_codec.dart';
import 'backup_crypto.dart';

export 'backup_codec.dart'
    show BackupDecodeResult, BackupDecodeSuccess, kBackupMaxBytes;

/// Whether the encoded document is over the size its own importer accepts.
bool exceedsBackupLimit(String json) =>
    utf8.encode(json).length > kBackupMaxBytes;

/// Decodes the picked backup document.
///
/// An encrypted envelope ([kEncryptedBackupFormat]) needs [passphrase];
/// without it — or with a wrong one — the failure reason is `encrypted` so
/// the importer can offer the prompt. Plaintext files decode exactly as
/// before.
///
/// The whole job runs in a worker isolate: the document is capped at 2 MB, and
/// decoding it on the UI isolate blocks the frame — and for an encrypted file
/// the Argon2id derivation must not run on the thread that draws.
///
/// A `flutter test` build decodes inline: an isolate completion never
/// arrives under the fake clock, so the import flow would hang
/// (probe-verified in this repo — see the report for the probe output).
Future<BackupDecodeResult> decodeBackup(
  Uint8List bytes, {
  String? passphrase,
}) async {
  // Sniffing the raw bytes answers "does this need a passphrase?" without
  // decoding 2 MiB on the UI isolate. The inline pass re-checks the envelope,
  // so a re-serialized file the sniff misses still classifies correctly.
  if (passphrase == null && _looksEncrypted(bytes)) {
    return const BackupDecodeFailure(BackupDecodeFailureReason.encrypted);
  }
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return _decodeInline(bytes, passphrase);
  }
  try {
    return await Isolate.run(() => _decodeInline(bytes, passphrase));
  } on Object {
    // The worker is unavailable: decode inline so the failure states stay
    // exactly the codec's.
    return _decodeInline(bytes, passphrase);
  }
}

/// The real worker-isolate decode. Exposed so a unit test can prove the
/// non-test path completes; the widget suite runs under the fake clock,
/// where isolate completions never arrive.
Future<BackupDecodeResult> decodeBackupInIsolate(Uint8List bytes) {
  return Isolate.run(
    () => decode(utf8.decode(bytes, allowMalformed: true)),
  );
}

/// Encrypts [json] behind [passphrase] on a worker isolate.
///
/// The KDF is memory-hard (Argon2id, 19 MiB), so it belongs off the thread
/// that draws. The presentation layer calls this instead of the crypto module
/// directly, which keeps the crypto behind the feature's data boundary.
Future<String> encryptBackupJsonInIsolate(
  String json,
  String passphrase,
) async {
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return encryptBackupJson(json, passphrase);
  }
  try {
    return await Isolate.run(() => encryptBackupJson(json, passphrase));
  } on Object {
    return encryptBackupJson(json, passphrase);
  }
}

/// Decodes one backup document, encrypted or plaintext.
///
/// Top-level on purpose: it is the closure body a worker isolate runs, so it
/// may capture only sendable values ([bytes] and [passphrase] are).
Future<BackupDecodeResult> _decodeInline(
  Uint8List bytes,
  String? passphrase,
) async {
  final text = utf8.decode(bytes, allowMalformed: true);
  if (isEncryptedBackupEnvelope(text)) {
    if (passphrase == null) {
      return const BackupDecodeFailure(BackupDecodeFailureReason.encrypted);
    }
    final unlocked = await decryptBackupJson(text, passphrase);
    if (unlocked == null) {
      return const BackupDecodeFailure(BackupDecodeFailureReason.encrypted);
    }
    return decode(unlocked);
  }
  return decode(text);
}

/// The byte prefix every encrypted envelope starts with.
///
/// The envelope is JSON this app produces, so its first bytes are stable; a
/// v1 and a v2 envelope differ only after the `_v`. Comparing raw bytes is
/// what keeps the plaintext path free of a UI-isolate decode.
final List<int> _envelopePrefix = utf8.encode(
  '{"app":"$kEncryptedBackupApp","format":"quran_yahdi_backup_encrypted_v',
);

/// Whether [bytes] start like an encrypted envelope.
bool _looksEncrypted(Uint8List bytes) {
  if (bytes.length < _envelopePrefix.length) return false;
  for (var i = 0; i < _envelopePrefix.length; i++) {
    if (bytes[i] != _envelopePrefix[i]) return false;
  }
  return true;
}
