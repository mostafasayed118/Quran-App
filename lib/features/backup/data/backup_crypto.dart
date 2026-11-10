/// Passphrase encryption for the user-controlled backup file.
///
/// The plaintext format stays untouched; this module produces and consumes
/// the encrypted envelope on top of it:
///
/// ```json
/// {
///   "app": "quran_yahdi",
///   "format": "quran_yahdi_backup_encrypted_v2",
///   "kdf": {"name": "argon2id", "memory": 19456, "iterations": 2,
///           "parallelism": 1, "salt": "…"},
///   "payload": "…"   // base64 of nonce(12) + ciphertext + mac(16)
/// }
/// ```
///
/// **Key derivation** is Argon2id at the OWASP minimum configuration
/// (`m = 19 MiB, t = 2, p = 1`) — the ratified decision in
/// `docs/superpowers/specs/2026-10-24-backup-encryption-decision.md:52-55`.
/// The document names PBKDF2-HMAC-SHA256 with 600,000 iterations only as the
/// fallback for a platform without Argon2id; on this stack Argon2id is
/// available AND cheaper (it is memory-hard, not HMAC-bound), so it is the
/// primary. The first envelope format (`…_v1`) used PBKDF2-HMAC-SHA256 at
/// 100,000 iterations and is still **readable**, so a backup written by an
/// earlier build keeps importing.
///
/// **The header is authenticated.** The `app` id, the `format` and the whole
/// `kdf` block are bound as GCM additional authenticated data, so a file
/// cannot swap its KDF id, its parameters or its app id without failing the
/// tag check. The v1 envelope had no AAD and never will.
///
/// A wrong passphrase is indistinguishable from a tampered file — both fail
/// GCM authentication and both surface as "wrong passphrase or corrupted
/// file".
///
/// The work runs on the calling isolate; the call sites move it behind
/// `Isolate.run` (see `backup_io.dart`), because Argon2id at 19 MiB is not
/// something to run on the thread that draws.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../core/utils/canonical_json.dart';
import 'backup_codec.dart';

/// The envelope format this build writes.
const String kEncryptedBackupFormat = 'quran_yahdi_backup_encrypted_v2';

/// The first envelope format: PBKDF2-HMAC-SHA256, no AAD.
///
/// Still recognised so a backup written by an earlier build keeps importing.
const String kEncryptedBackupFormatV1 = 'quran_yahdi_backup_encrypted_v1';

/// The app field of an encrypted envelope.
const String kEncryptedBackupApp = kBackupAppId;

/// The KDF ids the reader understands.
const String _kdfArgon2id = 'argon2id';
const String _kdfPbkdf2HmacSha256 = 'pbkdf2-hmac-sha256';

/// Argon2id parameters — the ratified OWASP minimum configuration.
const int kArgon2idMemoryKiB = 19 * 1024;
const int kArgon2idIterations = 2;
const int kArgon2idParallelism = 1;
const int kArgon2idHashLength = 32;

/// The legacy PBKDF2 iteration count, still honoured when reading a v1
/// envelope. It is the *floor* a v1 file may ask for, not a default.
const int kEncryptedBackupKdfIterations = 100000;

const int _saltBytes = 16;
const int _nonceBytes = 12;
const int _macBytes = 16;

/// The bounds the reader accepts for a file-provided KDF parameter.
///
/// The envelope is untrusted. Without a band a crafted file could demand
/// 10,000,000 PBKDF2 rounds (a multi-minute freeze on the thread that runs
/// the derivation) or a single round (which weakens the passphrase against an
/// offline search). The values are clamped, never trusted — and because the
/// header is authenticated as AAD, a file whose parameters were changed
/// fails the tag check anyway.
const int _minPbkdf2Iterations = 100000;
const int _maxPbkdf2Iterations = 600000;
const int _minArgon2idMemoryKiB = 8 * 1024;
const int _maxArgon2idMemoryKiB = 64 * 1024;
const int _maxArgon2idIterations = 4;
const int _maxArgon2idParallelism = 4;

/// The largest payload the reader accepts. The plaintext document is capped
/// at 2 MiB; the envelope adds base64 overhead on top.
const int _maxPayloadBytes = 4 * 1024 * 1024;

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
  final effectiveSalt = salt ?? _randomBytes(_saltBytes, random);
  final effectiveNonce = nonce ?? _randomBytes(_nonceBytes, random);
  final header = <String, Object?>{
    'app': kEncryptedBackupApp,
    'format': kEncryptedBackupFormat,
    'kdf': <String, Object?>{
      'name': _kdfArgon2id,
      'memory': kArgon2idMemoryKiB,
      'iterations': kArgon2idIterations,
      'parallelism': kArgon2idParallelism,
      'salt': base64Encode(effectiveSalt),
    },
  };
  final key = await _deriveKey(
    kdfName: _kdfArgon2id,
    salt: effectiveSalt,
    passphrase: passphrase,
    memoryKiB: kArgon2idMemoryKiB,
    iterations: kArgon2idIterations,
    parallelism: kArgon2idParallelism,
  );
  final clearText = utf8.encode(plaintext);
  try {
    final box = await _aesGcm.encrypt(
      clearText,
      secretKey: key,
      nonce: effectiveNonce,
      aad: _headerAad(header),
    );
    return jsonEncode({
      ...header,
      'payload': base64Encode(box.concatenation()),
    });
  } finally {
    key.destroy();
    clearText.fillRange(0, clearText.length, 0);
  }
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
  final format = decoded['format'];
  if (format != kEncryptedBackupFormat && format != kEncryptedBackupFormatV1) {
    return null;
  }
  return decoded.cast<String, Object?>();
}

/// Decrypts [envelope] with [passphrase]; returns the plaintext backup JSON,
/// or null when the passphrase is wrong or the envelope is malformed. Never
/// throws.
Future<String?> decryptBackupJson(String envelope, String passphrase) async {
  final map = encryptedEnvelopeOf(envelope);
  if (map == null) return null;
  final kdf = map['kdf'];
  if (kdf is! Map) return null;
  final salt = _b64(kdf, 'salt');
  final payload = map['payload'];
  if (salt == null || salt.length != _saltBytes || payload is! String) {
    return null;
  }
  final Uint8List blob;
  try {
    blob = base64Decode(payload);
  } on Object {
    return null;
  }
  if (blob.length <= _nonceBytes + _macBytes) return null;
  if (blob.length > _maxPayloadBytes) return null;
  final SecretBox box;
  try {
    box = SecretBox.fromConcatenation(
      blob,
      nonceLength: _nonceBytes,
      macLength: _macBytes,
    );
  } on Object {
    return null;
  }
  final name = kdf['name'];
  if (name is! String) return null;
  final isLegacy = map['format'] == kEncryptedBackupFormatV1;
  // A legacy envelope is read without AAD: that is how it was written, and
  // re-authenticating it would reject every backup an earlier build made.
  final aad = isLegacy ? const <int>[] : _headerAad(map);
  final SecretKey? key;
  try {
    key = await _deriveKey(
      kdfName: name,
      salt: salt,
      passphrase: passphrase,
      memoryKiB: _intOr(kdf['memory'], kArgon2idMemoryKiB),
      iterations: _intOr(kdf['iterations'], kArgon2idIterations),
      parallelism: _intOr(kdf['parallelism'], kArgon2idParallelism),
      legacy: isLegacy,
    );
  } on Object {
    return null;
  }
  try {
    final plain = await _aesGcm.decrypt(box, secretKey: key, aad: aad);
    return utf8.decode(plain);
  } on Object {
    // GCM authentication failure (wrong passphrase or tampered payload);
    // never leak which.
    return null;
  } finally {
    key.destroy();
  }
}

/// Derives the key with the KDF the envelope names.
///
/// [memoryKiB], [iterations] and [parallelism] come from the file when it is
/// read, so they are clamped to a bounded band before use.
Future<SecretKey> _deriveKey({
  required String kdfName,
  required List<int> salt,
  required String passphrase,
  required int memoryKiB,
  required int iterations,
  required int parallelism,
  bool legacy = false,
}) async {
  switch (kdfName) {
    case _kdfArgon2id:
      final algorithm = Argon2id(
        parallelism: parallelism.clamp(1, _maxArgon2idParallelism),
        memory: memoryKiB.clamp(_minArgon2idMemoryKiB, _maxArgon2idMemoryKiB),
        iterations: iterations.clamp(1, _maxArgon2idIterations),
        hashLength: kArgon2idHashLength,
      );
      return algorithm.deriveKeyFromPassword(
        password: passphrase,
        nonce: salt,
      );
    case _kdfPbkdf2HmacSha256:
      final algorithm = Pbkdf2.hmacSha256(
        iterations:
            iterations.clamp(_minPbkdf2Iterations, _maxPbkdf2Iterations),
        bits: 256,
      );
      return algorithm.deriveKeyFromPassword(
        password: passphrase,
        nonce: salt,
      );
    default:
      throw ArgumentError.value(kdfName, 'kdfName', 'unknown KDF');
  }
}

/// The canonical bytes authenticated as AAD: the envelope header.
///
/// The header is rebuilt from the PARSED file, so any change to the app id,
/// the format or the KDF block changes these bytes and fails the tag check.
List<int> _headerAad(Map<String, Object?> envelope) {
  final header = <String, Object?>{
    'app': envelope['app'],
    'format': envelope['format'],
    'kdf': envelope['kdf'],
  };
  return utf8.encode(canonicalJson(header));
}

Uint8List _randomBytes(int count, Random random) => Uint8List.fromList(
      List<int>.generate(count, (_) => random.nextInt(256)),
    );

int _intOr(Object? raw, int fallback) => raw is int ? raw : fallback;

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
