import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/backup_codec.dart';
import '../data/backup_merger.dart';

part 'backup_state.freezed.dart';

@freezed
sealed class BackupState with _$BackupState {
  /// Resting state; [busy] covers an in-flight export/import pick.
  const factory BackupState.idle({@Default(false) bool busy}) = BackupIdle;

  /// A decoded document awaits the user's «دمج» / «إلغاء» (zero writes yet).
  const factory BackupState.preview({
    required BackupDocument document,
    required BackupSummary summary,
  }) = BackupPreviewReady;

  /// Export share sheet dispatched (transient — the UI acknowledges to idle).
  const factory BackupState.exported() = BackupExported;

  /// Import merged and committed (transient — acknowledged to idle).
  const factory BackupState.imported({required BackupSummary summary}) =
      BackupImported;

  /// A localized failure arm; [duringExport] picks the export/import copy.
  const factory BackupState.failed({required bool duringExport}) = BackupFailed;

  /// The picked file is not a valid backup (size cap / decode guards).
  const factory BackupState.invalidFile() = BackupInvalidFile;
}
