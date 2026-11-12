import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:quran_yahdi/core/utils/canonical_json.dart';

/// Generates and signs the version-policy document.
///
/// The private seed is written only to the path the caller supplies; this
/// tool prints the public key. `sign` covers the exact canonical JSON the app
/// verifies, so a re-serialized document cannot change the signed bytes.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exitCode = 64;
    return;
  }
  try {
    switch (args[0]) {
      case 'generate':
        if (args.length < 2) {
          _usage();
          exitCode = 64;
          return;
        }
        await _generate(File(args[1]));
        return;
      case 'sign':
        if (args.length < 3) {
          _usage();
          exitCode = 64;
          return;
        }
        await _sign(File(args[1]), File(args[2]));
        return;
      case 'verify':
        if (args.length < 3) {
          _usage();
          exitCode = 64;
          return;
        }
        await _verify(File(args[1]), args[2]);
        return;
      default:
        _usage();
        exitCode = 64;
    }
  } on Object catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
  }
}

void _usage() {
  stderr.writeln(
    'usage:\n'
    '  generate <seed-out>\n'
    '  sign <json> <seed-file>\n'
    '  verify <json> <public-key-base64>',
  );
}

Future<void> _generate(File out) async {
  if (out.existsSync()) {
    throw StateError('refusing to overwrite ${out.path}');
  }
  final algorithm = Ed25519();
  final pair = await algorithm.newKeyPair();
  final seed = await pair.extractPrivateKeyBytes();
  final publicKey = await pair.extractPublicKey();
  out.parent.createSync(recursive: true);
  out.writeAsStringSync('${base64Encode(seed)}\n');
  stdout.writeln(base64Encode(publicKey.bytes));
}

Future<void> _sign(File file, File seedFile) async {
  final algorithm = Ed25519();
  final document = _readDocument(file);
  document.remove('signature');
  final seed = base64Decode(seedFile.readAsStringSync().trim());
  if (seed.length != 32) {
    throw const FormatException('the seed must decode to 32 bytes');
  }
  final pair = await algorithm.newKeyPairFromSeed(seed);
  final signature = await algorithm.sign(
    utf8.encode(canonicalJson(document)),
    keyPair: pair,
  );
  document['signature'] = base64Encode(signature.bytes);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
  );
  stdout.writeln('signed ${file.path}');
}

Future<void> _verify(File file, String publicKeyB64) async {
  final algorithm = Ed25519();
  final document = _readDocument(file);
  final signature = document.remove('signature');
  if (signature is! String) {
    throw const FormatException('missing signature');
  }
  final publicKey = SimplePublicKey(
    base64Decode(publicKeyB64),
    type: KeyPairType.ed25519,
  );
  final valid = await algorithm.verify(
    utf8.encode(canonicalJson(document)),
    signature: Signature(base64Decode(signature), publicKey: publicKey),
  );
  stdout.writeln(valid ? 'valid' : 'INVALID');
  if (!valid) exitCode = 1;
}

Map<String, Object?> _readDocument(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('the policy must be a JSON object');
  }
  return decoded;
}
