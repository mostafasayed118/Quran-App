import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_codec.dart' show kBackupMaxBytes;

/// A backup payload is over [kBackupMaxBytes].
class BackupTooLarge implements Exception {
  /// Creates the marker; the message is never shown to the user.
  const BackupTooLarge();
}

/// Injectable seam for the document picker; `null` = the user cancelled.
typedef BackupPickBytes = Future<Uint8List?> Function();

/// Injectable seam for the export share step; receives the encoded document.
typedef BackupShareJson = Future<void> Function(String json);

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
