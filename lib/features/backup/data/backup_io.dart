import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_codec.dart';
import 'backup_crypto.dart';

export 'backup_codec.dart'
    show BackupDecodeResult, BackupDecodeSuccess, kBackupMaxBytes;

/// A backup payload is over [kBackupMaxBytes].
class BackupTooLarge implements Exception {
  /// Creates the marker; the message is never shown to the user.
  const BackupTooLarge();
}

/// Injectable seam for the document picker; `null` = the user cancelled.
typedef BackupPickBytes = Future<Uint8List?> Function();

/// Injectable seam for the export share step; receives the encoded document.
typedef BackupShareJson = Future<void> Function(String json);

/// Whether the encoded document is over the size its own importer accepts.
bool exceedsBackupLimit(String json) =>
    utf8.encode(json).length > kBackupMaxBytes;

/// The real document picker, with the size gate BEFORE the read.
Future<Uint8List?> pickBackupBytes() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  if (file == null) return null;
  // Size gate BEFORE the read: reading a multi-GB file first would OOM.
  final length = await _pickedLength(file);
  if (length != null && length > kBackupMaxBytes) {
    throw const BackupTooLarge();
  }
  if (length == null) {
    return _readBounded(file);
  }
  return file.readAsBytes();
}

Future<Uint8List> _readBounded(PlatformFile file) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in file.readAsByteStream()) {
    builder.add(chunk);
    if (builder.length > kBackupMaxBytes) {
      throw const BackupTooLarge();
    }
  }
  return builder.takeBytes();
}

/// The picked file's length in bytes, without reading its bytes, or null
/// when the picker cannot report it cheaply.
Future<int?> _pickedLength(PlatformFile file) async {
  final path = file.path;
  if (path != null) {
    try {
      return await File(path).length();
    } on FileSystemException {
      // No readable path: fall back to the picker's reported size.
    }
  }
  return file.lengthSync();
}

/// The real share sheet: writes a temporary JSON file, shares it, deletes it.
Future<void> shareBackupJson(String json) async {
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().toIso8601String().substring(0, 10);
  final file = File(p.join(dir.path, 'quran_yahdi_backup_$stamp.json'));
  await file.writeAsString(json, flush: true);
  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } finally {
    try {
      await file.delete();
    } on FileSystemException {
      // Best-effort cleanup: a leftover temp file fails nothing.
    }
  }
}

/// Decodes the picked backup document.
///
/// An encrypted envelope ([kEncryptedBackupFormat]) needs [passphrase];
/// without it — or with a wrong one — the failure reason is `encrypted` so
/// the importer can offer the prompt. Plaintext files decode exactly as
/// before.
///
/// The parse runs in a worker isolate: the document is capped at 2 MB, and
/// decoding it on the UI isolate blocks the frame for the whole JSON parse.
///
/// A `flutter test` build decodes inline: an isolate completion never
/// arrives under the fake clock, so the import flow would hang
/// (probe-verified in this repo — see the report for the probe output).
Future<BackupDecodeResult> decodeBackup(
  Uint8List bytes, {
  String? passphrase,
}) async {
  final text = utf8.decode(bytes, allowMalformed: true);
  if (isEncryptedBackupEnvelope(text)) {
    if (passphrase != null) {
      final unlocked = await decryptBackupJson(text, passphrase);
      if (unlocked != null) {
        return decode(unlocked);
      }
    }
    return const BackupDecodeFailure(BackupDecodeFailureReason.encrypted);
  }
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return decode(text);
  }
  try {
    return await decodeBackupInIsolate(bytes);
  } on Object {
    // The worker is unavailable: decode inline so the failure states stay
    // exactly the codec's.
    return decode(text);
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
