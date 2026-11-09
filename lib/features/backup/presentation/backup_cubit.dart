import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/backup_crypto.dart';
import '../data/backup_io.dart';
import '../data/backup_service.dart';
import '../domain/backup_models.dart';
import 'backup_state.dart';

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
        _pickBytes = pickBytes ?? pickBackupBytes,
        _shareJson = shareJson ?? shareBackupJson,
        super(const BackupState.idle());

  final BackupService _service;
  final BackupPickBytes _pickBytes;
  final BackupShareJson _shareJson;

  /// Bytes of the pending encrypted import; held between
  /// [BackupState.passphraseRequired] and [submitImportPassphrase].
  Uint8List? _pendingEncryptedBytes;

  /// Encodes every backed-up entity and hands the JSON to the share sheet.
  /// Never throws: a failure emits the `failed(duringExport: true)` state.
  Future<void> export() async {
    if (isClosed) return;
    if (!_canStart) return;
    emit(const BackupState.idle(busy: true));
    try {
      final json = await _service.exportJson();
      // On export the encoded JSON is measured before it is shared: the app
      // must never emit a file its own importer would reject.
      if (exceedsBackupLimit(json)) {
        throw const BackupTooLarge();
      }
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
    if (isClosed) return;
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
      final result = await decodeBackup(bytes);
      if (isClosed) return;
      if (result is BackupDecodeFailure &&
          result.reason == BackupDecodeFailureReason.encrypted) {
        _pendingEncryptedBytes = bytes;
        emit(const BackupState.passphraseRequired());
        return;
      }
      if (result is! BackupDecodeSuccess) {
        emit(const BackupState.invalidFile());
        return;
      }
      final summary = await _service.preview(result.document);
      if (isClosed) return;
      emit(BackupState.preview(document: result.document, summary: summary));
    } on BackupTooLarge {
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

  /// Encodes the backup as AES-256-GCM behind [passphrase] and shares the
  /// envelope. An empty passphrase fails fast to the export-failure state;
  /// the UI enforces non-empty first.
  Future<void> exportEncrypted(String passphrase) async {
    if (isClosed) return;
    if (!_canStart) return;
    if (passphrase.isEmpty) {
      emit(const BackupState.failed(duringExport: true));
      return;
    }
    emit(const BackupState.idle(busy: true));
    try {
      final json = await _service.exportJson();
      final encrypted = await encryptBackupJson(json, passphrase);
      // Never emit a file this app's own importer would reject.
      if (exceedsBackupLimit(encrypted)) {
        throw const BackupTooLarge();
      }
      await _shareJson(encrypted);
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

  /// Unlocks the pending encrypted file with [passphrase] and, on success,
  /// shows the same read-only merge preview as the plaintext import.
  Future<void> submitImportPassphrase(String passphrase) async {
    final bytes = _pendingEncryptedBytes;
    if (isClosed || bytes == null) return;
    emit(const BackupState.idle(busy: true));
    try {
      final result = await decodeBackup(bytes, passphrase: passphrase);
      if (isClosed) return;
      if (result is! BackupDecodeSuccess) {
        _pendingEncryptedBytes = null;
        if (result is BackupDecodeFailure &&
            result.reason == BackupDecodeFailureReason.encrypted) {
          // Wrong passphrase or tampered payload: honest import failure.
          emit(const BackupState.failed(duringExport: false));
        } else {
          emit(const BackupState.invalidFile());
        }
        return;
      }
      final summary = await _service.preview(result.document);
      if (isClosed) return;
      _pendingEncryptedBytes = null;
      emit(BackupState.preview(document: result.document, summary: summary));
    } on Object catch (error, stackTrace) {
      dev.log('backup import failed',
          name: 'quran_yahdi/backup',
          error: error.runtimeType,
          stackTrace: stackTrace);
      _pendingEncryptedBytes = null;
      if (isClosed) return;
      emit(const BackupState.failed(duringExport: false));
    }
  }

  /// Drops the pending encrypted file without decoding it.
  void cancelEncryptedImport() {
    if (isClosed) return;
    _pendingEncryptedBytes = null;
    if (state is BackupPassphraseRequired) emit(const BackupState.idle());
  }

  /// The preview dialog's confirm: applies inside the service transaction.
  Future<void> confirmImport() async {
    if (isClosed) return;
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
    if (isClosed) return;
    if (state is BackupPreviewReady) emit(const BackupState.idle());
  }

  /// After the success snackbar / a dismissed error strip.
  void acknowledge() {
    if (isClosed) return;
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
}
