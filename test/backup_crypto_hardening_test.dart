import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_crypto.dart';

/// Pins the two properties the hardened envelope claims:
///
/// 1. A file written by the previous build (`…_v1`: PBKDF2, no AAD) still
///    imports, so nobody loses a backup they already made.
/// 2. A `…_v2` file authenticates its header as AAD, so a header field cannot
///    be changed without failing the tag check.
void main() {
  test('a v1 envelope (PBKDF2, no AAD) still decrypts', () async {
    const plain = '{"app":"quran_yahdi","format":1}';
    const passphrase = 'legacy pass';
    final salt = Uint8List.fromList(List<int>.filled(16, 3));
    final nonce = Uint8List.fromList(List<int>.filled(12, 5));

    // Reproduce exactly what the previous build wrote: PBKDF2-HMAC-SHA256 at
    // 100,000 iterations, no AAD, one concatenated payload.
    final key = await Pbkdf2.hmacSha256(iterations: 100000, bits: 256)
        .deriveKeyFromPassword(password: passphrase, nonce: salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plain),
      secretKey: key,
      nonce: nonce,
    );
    final v1 = jsonEncode({
      'app': 'quran_yahdi',
      'format': 'quran_yahdi_backup_encrypted_v1',
      'kdf': {
        'name': 'pbkdf2-hmac-sha256',
        'iterations': 100000,
        'salt': base64Encode(salt),
      },
      'payload': base64Encode(box.concatenation()),
    });

    expect(isEncryptedBackupEnvelope(v1), isTrue);
    expect(await decryptBackupJson(v1, passphrase), plain);
    expect(await decryptBackupJson(v1, 'wrong'), isNull);
  });

  test('a v2 envelope authenticates its header as AAD', () async {
    const passphrase = 'p';
    final envelope = await encryptBackupJson('{"a":1}', passphrase);
    // Control: the untouched envelope opens.
    expect(await decryptBackupJson(envelope, passphrase), '{"a":1}');

    final map = jsonDecode(envelope) as Map<String, Object?>;
    final kdf = Map<String, Object?>.from(map['kdf']! as Map);
    // An extra header field changes the AAD without changing the key
    // derivation, so only the tag check can catch it.
    kdf['note'] = 'tampered';
    map['kdf'] = kdf;

    expect(await decryptBackupJson(jsonEncode(map), passphrase), isNull);
  });

  test('an out-of-band iteration count is clamped, never trusted', () async {
    final envelope = await encryptBackupJson('{"a":1}', 'p');
    final map = jsonDecode(envelope) as Map<String, Object?>;
    final kdf = Map<String, Object?>.from(map['kdf']! as Map);
    kdf['iterations'] = 1; // the downgrade an attacker would ask for
    map['kdf'] = kdf;

    // A clamped derivation produces a different key, so the envelope cannot
    // be opened with a weakened work factor.
    expect(await decryptBackupJson(jsonEncode(map), 'p'), isNull);
  });

  test('a payload larger than the cap is rejected before any derivation',
      () async {
    final envelope = await encryptBackupJson('{"a":1}', 'p');
    final map = jsonDecode(envelope) as Map<String, Object?>;
    map['payload'] = base64Encode(Uint8List(5 * 1024 * 1024));
    expect(await decryptBackupJson(jsonEncode(map), 'p'), isNull);
  });
}
