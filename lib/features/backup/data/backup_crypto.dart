/// Passphrase encryption for the user-controlled backup file.
///
/// The plaintext format stays untouched; this module produces and consumes
/// the encrypted envelope on top of it:
///
/// ```json
/// {
///   "app": "quran_yahdi",
///   "format": "quran_yahdi_backup_encrypted_v1",
///   "kdf": {"name": "pbkdf2-hmac-sha256", "iterations": 100000, "salt": "…"},
///   "payload": "…"   // base64 of nonce(12) + ciphertext + mac(16)
/// }
/// ```
///
/// Key derivation is PBKDF2-HMAC-SHA256 (100k iterations, 16-byte salt) and
/// encryption is AES-256-GCM (12-byte nonce). A wrong passphrase is
/// indistinguishable from a tampered file — both fail GCM authentication and
/// both surface as "wrong passphrase or corrupted file".
///
/// The work runs on the calling isolate: it is one user-initiated tap, and
/// the async/AES internals are pure Dart. If profiling ever flags it, move
/// the call sites behind `Isolate.run` like [exportJson] does.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Envelope marker checked by the importer before any decoding happens.
const String kEncryptedBackupFormat = 'quran_yahdi_backup_encrypted_v1';

/// The app field of an encrypted envelope; mirrors `kBackupAppId`.
const String kEncryptedBackupApp = 'quran_yahdi';

/// PBKDF2 iterations pinned in the envelope; readers honor what the file
/// says, so a future bump does not break old backups.
const int kEncryptedBackupKdfIterations = 100000;

const int _saltBytes = 16;
const int _nonceBytes = 12;

final Pbkdf2 _pbkdf2 = Pbkdf2.hmacSha256(
  iterations: kEncryptedBackupKdfIterations,
  bits: 256,
);
final AesGcm _aesGcm = AesGcm.with256bits();

/// Encrypts [plaintext] behind [passphrase] and returns the envelope JSON.
/// [salt]/[nonce] are test seams; production fills them with secure random
/// bytes.
Future<String> encryptBackupJson(
  String plaintext,
  String passphrase, {
  Uint8List? salt,
  Uint8List? nonce,
}) async {
  if (passphrase.isEmpty) {
    throw ArgumentError.value(passphrase, 'passphrase', 'must not be empty');
  }
  final random = Random.secure();
  final effectiveSalt = salt ??
      Uint8List.fromList(
        List<int>.generate(_saltBytes, (_) => random.nextInt(256)),
      );
  final effectiveNonce = nonce ??
      Uint8List.fromList(
        List<int>.generate(_nonceBytes, (_) => random.nextInt(256)),
      );
  final key = await _pbkdf2.deriveKeyFromPassword(
    password: passphrase,
    nonce: effectiveSalt,
  );
  final box = await _aesGcm.encrypt(
    utf8.encode(plaintext),
    secretKey: key,
    nonce: effectiveNonce,
  );
  return jsonEncode({
    'app': kEncryptedBackupApp,
    'format': kEncryptedBackupFormat,
    'kdf': {
      'name': 'pbkdf2-hmac-sha256',
      'iterations': kEncryptedBackupKdfIterations,
      'salt': base64Encode(effectiveSalt),
    },
    'payload': base64Encode(box.concatenation()),
  });
}

/// Whether [text] is an encrypted backup envelope (and must not be decoded
/// as plaintext). Never throws: any malformed JSON answers false.
bool isEncryptedBackupEnvelope(String text) =>
    encryptedEnvelopeOf(text) != null;

/// Decodes [text] as an encrypted envelope, or returns null when it is not
/// one. The caller decides what to do with a non-envelope text.
Map<String, Object?>? encryptedEnvelopeOf(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on Object {
    return null;
  }
  if (decoded is! Map) return null;
  if (decoded['app'] != kEncryptedBackupApp) return null;
  if (decoded['format'] != kEncryptedBackupFormat) return null;
  return decoded.cast<String, Object?>();
}

/// Decrypts [envelope] with [passphrase]; returns the plaintext backup JSON,
/// or null when the passphrase is wrong or the envelope is malformed. Never
/// throws.
Future<String?> decryptBackupJson(String envelope, String passphrase) async {
  final map = encryptedEnvelopeOf(envelope);
  if (map == null) return null;
  final kdf = map['kdf'];
  final salt = _b64(kdf, 'salt');
  final payload = map['payload'];
  if (salt == null || payload is! String) return null;
  var iterations = kEncryptedBackupKdfIterations;
  if (kdf is Map) {
    final raw = kdf['iterations'];
    if (raw is int) iterations = raw.clamp(1, 10000000);
  }
  final Uint8List blob;
  try {
    blob = base64Decode(payload);
  } on Object {
    return null;
  }
  if (blob.length <= _nonceBytes + 16) return null;
  final SecretBox box;
  try {
    box = SecretBox.fromConcatenation(
      blob,
      nonceLength: _nonceBytes,
      macLength: 16,
    );
  } on Object {
    return null;
  }
  try {
    final pbkdf2 = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
    final key = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final plain = await _aesGcm.decrypt(box, secretKey: key);
    return utf8.decode(plain);
  } on Object {
    // GCM authentication failure (wrong passphrase or tampered payload);
    // never leak which.
    return null;
  }
}

Uint8List? _b64(Object? map, String key) {
  if (map is! Map) return null;
  final value = map[key];
  if (value is! String) return null;
  try {
    return base64Decode(value);
  } on Object {
    return null;
  }
}
