import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_crypto.dart';
import 'package:quran_yahdi/features/backup/data/backup_io.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart'
    as state;

void main() {
  test('encrypt/decrypt round-trips a backup payload', () async {
    final plain = jsonEncode({'app': 'quran_yahdi', 'format': 1, 'x': 'y'});
    final envelope = await encryptBackupJson(plain, 'correct horse battery');

    expect(isEncryptedBackupEnvelope(envelope), isTrue);
    expect(envelope.contains('"ciphertext"'), isFalse); // payload is one blob
    expect(envelope.contains('correct horse battery'), isFalse);

    final unlocked = await decryptBackupJson(envelope, 'correct horse battery');
    expect(unlocked, plain);
  });

  test('a wrong passphrase yields null, never an exception', () async {
    final envelope = await encryptBackupJson('{"a":1}', 'right');
    expect(await decryptBackupJson(envelope, 'wrong'), isNull);
  });

  test('a tampered payload fails authentication', () async {
    final salt = Uint8List.fromList(List<int>.filled(16, 7));
    final nonce = Uint8List.fromList(List<int>.filled(12, 9));
    final envelope = await encryptBackupJson(
      '{"secret":"data"}',
      'pass',
      salt: salt,
      nonce: nonce,
    );
    final map = jsonDecode(envelope) as Map<String, Object?>;
    final payload = base64Decode(map['payload']! as String);
    payload[payload.length - 1] ^= 0x01; // flip one bit in the MAC
    map['payload'] = base64Encode(payload);
    final tampered = jsonEncode(map);

    expect(await decryptBackupJson(tampered, 'pass'), isNull);
    expect(isEncryptedBackupEnvelope(tampered), isTrue);
  });

  test(
      'decodeBackup: encrypted file without passphrase is reported, not '
      'decoded', () async {
    final envelope = await encryptBackupJson(
      jsonEncode({
        'app': 'quran_yahdi',
        'format': 1,
        'exportedAt': '2026-11-09T00:00:00.000',
        'schemaVersion': 1,
        'data': <String, Object?>{
          'bookmarks': <Object?>[],
          'lastReadAyahId': null,
          'khatma': <Object?>[],
          'prayerLog': <Object?>[],
          'tasbih': null,
          'settings': <String, String>{},
        },
      }),
      'pass',
    );
    final bytes = Uint8List.fromList(utf8.encode(envelope));

    final locked = await decodeBackup(bytes);
    expect(locked, isA<BackupDecodeFailure>());
    expect(
      (locked as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.encrypted,
    );

    final wrong = await decodeBackup(bytes, passphrase: 'nope');
    expect(wrong, isA<BackupDecodeFailure>());
    expect(
      (wrong as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.encrypted,
    );

    final unlocked = await decodeBackup(bytes, passphrase: 'pass');
    expect(unlocked, isA<BackupDecodeSuccess>());
  });

  test('a plaintext backup decodes exactly as before', () async {
    final document = <String, Object?>{
      'app': 'quran_yahdi',
      'format': 1,
      'exportedAt': '2026-11-09T00:00:00.000',
      'schemaVersion': 1,
      'data': <String, Object?>{
        'bookmarks': <Object?>[],
        'lastReadAyahId': null,
        'khatma': <Object?>[],
        'prayerLog': <Object?>[],
        'tasbih': null,
        'settings': <String, String>{},
      },
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(document)));
    final result = await decodeBackup(bytes);
    expect(result, isA<BackupDecodeSuccess>());
  });

  test('an empty passphrase is refused by the encryptor', () async {
    await expectLater(
      encryptBackupJson('{}', ''),
      throwsArgumentError,
    );
  });

  test('the exported state family compiles with its new variant', () {
    const event = state.BackupState.passphraseRequired();
    expect(event, isA<state.BackupPassphraseRequired>());
  });
}
