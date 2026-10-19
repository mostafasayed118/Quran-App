import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

/// Backup & restore surface: export shares the encoded JSON file through the
/// system share sheet; import picks a `.json` file, decodes it with the
/// fail-closed guards, shows the merge preview and applies on confirmation.
/// The preview is read-only; cancel writes nothing by construction.
class BackupCubit extends Cubit<BackupState> {
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

  Future<void> export() async {
    if (!_isIdle) return;
    emit(const BackupState.idle(busy: true));
    try {
      final json = await _service.exportJson();
      await _shareJson(json);
      if (isClosed) return;
      emit(const BackupState.exported());
    } on Object catch (error, stackTrace) {
      dev.log('backup export failed',
          name: 'quran_yahdi/backup', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const BackupState.failed(duringExport: true));
    }
  }

  Future<void> importFromFile() async {
    if (!_isIdle) return;
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
      final result = decode(utf8.decode(bytes, allowMalformed: true));
      if (result is! BackupDecodeSuccess) {
        emit(const BackupState.invalidFile());
        return;
      }
      final summary = await _service.preview(result.document);
      if (isClosed) return;
      emit(BackupState.preview(document: result.document, summary: summary));
    } on Object catch (error, stackTrace) {
      dev.log('backup import failed',
          name: 'quran_yahdi/backup', error: error, stackTrace: stackTrace);
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
          name: 'quran_yahdi/backup', error: error, stackTrace: stackTrace);
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

  bool get _isIdle {
    final current = state;
    return current is BackupIdle && !current.busy;
  }

  static Future<Uint8List?> _defaultPickBytes() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  static Future<void> _defaultShareJson(String json) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File(p.join(dir.path, 'quran_yahdi_backup_$stamp.json'));
    await file.writeAsString(json, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
