import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_codec.dart';
import '../data/backup_service.dart';
import 'backup_state.dart';

/// Injectable seam for the document picker; `null` = the user cancelled.
typedef BackupPickBytes = Future<Uint8List?> Function();

/// Injectable seam for the export share step; receives the encoded document.
typedef BackupShareJson = Future<void> Function(String json);

/// The picked file is over [kBackupMaxBytes]: the picker reports the
/// on-disk length before the bytes are read, so an oversized file never
/// reaches memory.
class _BackupTooLarge implements Exception {
  const _BackupTooLarge();
}

/// Backup & restore surface: export shares the encoded JSON file through the
/// system share sheet; import picks a `.json` file, decodes it with the
/// fail-closed guards, shows the merge preview and applies on confirmation.
/// The preview is read-only; cancel writes nothing by construction.
class BackupCubit extends Cubit<BackupState> {
  /// Wires the cubit to the service plus the two platform seams (file pick
  /// and share sheet); both default to the real platform implementations and
  /// are replaced by doubles in tests.
  BackupCubit({
    required BackupService service,
    BackupPickBytes? pickBytes,
    BackupShareJson? shareJson,
  })  : _service = service,
        _pickBytes = pickBytes ?? _defaultPickBytes,
        _shareJson = shareJson ?? _defaultShareJson,
        super(const BackupState.idle());

  final BackupService _service;
  final BackupPickBytes _pickBytes;
  final BackupShareJson _shareJson;

  /// Encodes every backed-up entity and hands the JSON to the share sheet.
  /// Never throws: a failure emits the `failed(duringExport: true)` state.
  Future<void> export() async {
    if (!_canStart) return;
    emit(const BackupState.idle(busy: true));
    try {
      final json = await _service.exportJson();
      await _shareJson(json);
      if (isClosed) return;
      emit(const BackupState.exported());
    } on Object catch (error, stackTrace) {
      dev.log('backup export failed',
          name: 'quran_yahdi/backup',
          error: error.runtimeType,
          stackTrace: stackTrace);
      if (isClosed) return;
      emit(const BackupState.failed(duringExport: true));
    }
  }

  /// Picks a backup file, decodes it with the fail-closed guards and emits the
  /// read-only merge preview. Nothing is written here — the write happens in
  /// [confirmImport] after the user confirms.
  Future<void> importFromFile() async {
    if (!_canStart) return;
    emit(const BackupState.idle(busy: true));
    try {
      final bytes = await _pickBytes();
      if (isClosed) return;
      if (bytes == null) {
        emit(const BackupState.idle());
        return;
      }
      if (bytes.length > kBackupMaxBytes) {
        emit(const BackupState.invalidFile());
        return;
      }
      final result = await _decodeBackup(bytes);
      if (result is! BackupDecodeSuccess) {
        emit(const BackupState.invalidFile());
        return;
      }
      final summary = await _service.preview(result.document);
      if (isClosed) return;
      emit(BackupState.preview(document: result.document, summary: summary));
    } on _BackupTooLarge {
      if (isClosed) return;
      emit(const BackupState.invalidFile());
    } on Object catch (error, stackTrace) {
      // The error MESSAGE is never logged: a jsonDecode failure embeds a
      // snippet of the imported file, and the imported file is user content.
      // The runtime type is enough to diagnose the failure.
      dev.log('backup import failed',
          name: 'quran_yahdi/backup',
          error: error.runtimeType,
          stackTrace: stackTrace);
      if (isClosed) return;
      emit(const BackupState.failed(duringExport: false));
    }
  }

  /// The preview dialog's confirm: applies inside the service transaction.
  Future<void> confirmImport() async {
    final current = state;
    if (current is! BackupPreviewReady) return;
    emit(const BackupState.idle(busy: true));
    try {
      final outcome = await _service.apply(current.document);
      if (isClosed) return;
      emit(BackupState.imported(summary: outcome.summary));
    } on Object catch (error, stackTrace) {
      dev.log('backup apply failed',
          name: 'quran_yahdi/backup',
          error: error.runtimeType,
          stackTrace: stackTrace);
      if (isClosed) return;
      emit(const BackupState.failed(duringExport: false));
    }
  }

  /// The preview dialog's cancel — zero writes by construction.
  void cancelPreview() {
    if (state is BackupPreviewReady) emit(const BackupState.idle());
  }

  /// After the success snackbar / a dismissed error strip.
  void acknowledge() {
    if (state is! BackupIdle) emit(const BackupState.idle());
  }

  /// A new export/import may start from rest or from a terminal failure —
  /// both entry points emit `idle(busy: true)` first, so a retry after a
  /// failure is not silently ignored while the section keeps the buttons
  /// enabled.
  bool get _canStart {
    final current = state;
    if (current is BackupIdle) return !current.busy;
    return current is BackupFailed || current is BackupInvalidFile;
  }

  /// Decodes the picked backup document.
  ///
  /// The parse runs in a worker isolate: the document is capped at 2 MB, and
  /// decoding it on the UI isolate blocks the frame for the whole JSON parse.
  ///
  /// A `flutter test` build decodes inline: an isolate completion never
  /// arrives under the fake clock, so the import flow would hang
  /// (probe-verified in this repo — see the report for the probe output).
  static Future<BackupDecodeResult> _decodeBackup(Uint8List bytes) async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      return decode(utf8.decode(bytes, allowMalformed: true));
    }
    try {
      return await decodeInIsolate(bytes);
    } on Object {
      // The worker is unavailable: decode inline so the failure states stay
      // exactly the codec's.
      return decode(utf8.decode(bytes, allowMalformed: true));
    }
  }

  /// The real worker-isolate decode. Exposed so a unit test can prove the
  /// non-test path completes; the widget suite runs under the fake clock,
  /// where isolate completions never arrive.
  @visibleForTesting
  static Future<BackupDecodeResult> decodeInIsolate(Uint8List bytes) {
    return Isolate.run(
      () => decode(utf8.decode(bytes, allowMalformed: true)),
    );
  }

  static Future<Uint8List?> _defaultPickBytes() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    // Size gate BEFORE the read: reading a multi-GB file first would OOM.
    final length = await _pickedLength(file);
    if (length != null && length > kBackupMaxBytes) {
      throw const _BackupTooLarge();
    }
    if (length == null) {
      return _readBounded(file);
    }
    return file.readAsBytes();
  }

  static Future<Uint8List> _readBounded(PlatformFile file) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      builder.add(chunk);
      if (builder.length > kBackupMaxBytes) {
        throw const _BackupTooLarge();
      }
    }
    return builder.takeBytes();
  }

  /// The picked file's length in bytes, without reading its bytes, or null
  /// when the picker cannot report it cheaply.
  static Future<int?> _pickedLength(PlatformFile file) async {
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

  static Future<void> _defaultShareJson(String json) async {
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
}
