import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/error_strip.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_merger.dart';
import 'backup_cubit.dart';
import 'backup_state.dart';

/// The «النسخ الاحتياطي والاستعادة» settings section: an export row (share
/// sheet) and an import row (document picker → preview dialog → merge).
/// Composed into the settings screen by the app shell, so this feature keeps
/// zero imports from other features.
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<BackupCubit>();
    return BlocConsumer<BackupCubit, BackupState>(
      listener: (context, state) {
        switch (state) {
          case BackupExported():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.backupExportSuccess)),
            );
            cubit.acknowledge();
          case BackupImported():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.backupImportSuccess)),
            );
            cubit.acknowledge();
          case BackupPreviewReady(:final summary):
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => _PreviewDialog(
                summary: summary,
                onCancel: cubit.cancelPreview,
                onMerge: cubit.confirmImport,
              ),
            );
          case BackupIdle() || BackupFailed() || BackupInvalidFile():
            break;
        }
      },
      builder: (context, state) {
        final canAct = switch (state) {
          BackupIdle(:final busy) => !busy,
          BackupFailed() || BackupInvalidFile() => true,
          _ => false,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: loc.backupSectionTitle),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(loc.backupExport),
              enabled: canAct,
              onTap: canAct ? cubit.export : null,
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text(loc.backupImport),
              enabled: canAct,
              onTap: canAct ? cubit.importFromFile : null,
            ),
            if (state is BackupFailed)
              ErrorStrip(
                state.duringExport
                    ? loc.backupExportFailure
                    : loc.backupImportFailure,
                icon: Icons.error_outline,
                onDismiss: cubit.acknowledge,
              ),
            if (state is BackupInvalidFile)
              ErrorStrip(
                loc.backupInvalidFile,
                icon: Icons.error_outline,
                onDismiss: cubit.acknowledge,
              ),
          ],
        );
      },
    );
  }
}

/// Per-entity preview: only the lines that will actually change, merge/cancel.
class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({
    required this.summary,
    required this.onCancel,
    required this.onMerge,
  });

  final BackupSummary summary;
  final VoidCallback onCancel;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lines = <String>[
      if (summary.newBookmarks > 0)
        loc.backupPreviewBookmarks(summary.newBookmarks.toArabicIndic),
      if (summary.lastReadChanged) loc.backupPreviewLastRead,
      if (summary.mergedPrayerDays > 0)
        loc.backupPreviewPrayerDays(summary.mergedPrayerDays.toArabicIndic),
      if (summary.planReplaced) loc.backupPreviewPlan,
      if (summary.tasbihChanged) loc.backupPreviewTasbih,
      if (summary.settingsKeysApplied > 0)
        loc.backupPreviewSettings(summary.settingsKeysApplied.toArabicIndic),
    ];
    return AlertDialog(
      title: Text(loc.backupPreviewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel();
          },
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onMerge();
          },
          child: Text(loc.backupMerge),
        ),
      ],
    );
  }
}
