import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_localizations_digits.dart';
import '../../../core/widgets/app_toast.dart';
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
            AppToast.show(
              context,
              loc.backupExportSuccess,
              tone: ToastTone.success,
            );
            cubit.acknowledge();
          case BackupImported():
            AppToast.show(
              context,
              loc.backupImportSuccess,
              tone: ToastTone.success,
            );
            cubit.acknowledge();
          case BackupPreviewReady(:final summary):
            unawaited(showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => _PreviewDialog(
                summary: summary,
                onCancel: cubit.cancelPreview,
                onMerge: cubit.confirmImport,
              ),
            ).then((_) {
              if (!cubit.isClosed && cubit.state is BackupPreviewReady) {
                cubit.cancelPreview();
              }
            }));
          case BackupPassphraseRequired():
            unawaited(showDialog<void>(
              context: context,
              // Back/outside-tap must not leave the section stuck in
              // passphraseRequired with every action disabled.
              barrierDismissible: false,
              builder: (dialogContext) => _ImportPassphraseDialog(
                onSubmit: (passphrase) {
                  Navigator.of(dialogContext).pop();
                  cubit.submitImportPassphrase(passphrase);
                },
                onCancel: cubit.cancelEncryptedImport,
              ),
            ).then((_) {
              if (!cubit.isClosed && cubit.state is BackupPassphraseRequired) {
                cubit.cancelEncryptedImport();
              }
            }));
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
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.backupUnencryptedWarning,
                      // A permanent caveat, not an error: real failures below
                      // keep the error styling via ErrorStrip.
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(loc.backupExportEncrypted),
              enabled: canAct,
              onTap: canAct
                  ? () => unawaited(showDialog<void>(
                        context: context,
                        builder: (dialogContext) => _ExportPassphraseDialog(
                          onConfirmed: (passphrase) {
                            Navigator.of(dialogContext).pop();
                            cubit.exportEncrypted(passphrase);
                          },
                        ),
                      ))
                  : null,
              subtitle: Text(
                loc.backupEncryptedExportHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
        loc.backupPreviewBookmarks(loc.number(summary.newBookmarks)),
      if (summary.lastReadChanged) loc.backupPreviewLastRead,
      if (summary.mergedPrayerDays > 0)
        loc.backupPreviewPrayerDays(loc.number(summary.mergedPrayerDays)),
      if (summary.planReplaced) loc.backupPreviewPlan,
      if (summary.tasbihChanged) loc.backupPreviewTasbih,
      if (summary.settingsKeysApplied > 0)
        loc.backupPreviewSettings(loc.number(summary.settingsKeysApplied)),
      if (summary.rejectedEntries > 0)
        loc.backupPreviewRejected(loc.number(summary.rejectedEntries)),
    ];
    if (lines.isEmpty) lines.add(loc.backupPreviewNothing);
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
          onPressed: summary.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop();
                  onMerge();
                },
          child: Text(loc.backupMerge),
        ),
      ],
    );
  }
}

/// Export-with-passphrase dialog: collects the secret twice, blocks empty
/// and mismatched entries with an inline message.
class _ExportPassphraseDialog extends StatefulWidget {
  const _ExportPassphraseDialog({required this.onConfirmed});

  final void Function(String passphrase) onConfirmed;

  @override
  State<_ExportPassphraseDialog> createState() =>
      _ExportPassphraseDialogState();
}

class _ExportPassphraseDialogState extends State<_ExportPassphraseDialog> {
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    final first = _passphrase.text;
    final second = _confirm.text;
    if (first.isEmpty) {
      setState(() => _error = loc.backupPassphraseEmpty);
      return;
    }
    if (first != second) {
      setState(() => _error = loc.backupPassphraseMismatch);
      return;
    }
    widget.onConfirmed(first);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.backupExportEncrypted),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passphrase,
            autofocus: true,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: loc.backupEncryptedPassphrase,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          TextField(
            controller: _confirm,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: loc.backupEncryptedConfirmPassphrase,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.backupPassphraseCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(loc.backupPassphraseConfirm),
        ),
      ],
    );
  }
}

/// Import passphrase prompt: single field; wrong entries land in the normal
/// import-failure strip via the cubit.
class _ImportPassphraseDialog extends StatefulWidget {
  const _ImportPassphraseDialog(
      {required this.onSubmit, required this.onCancel});

  final void Function(String passphrase) onSubmit;
  final VoidCallback onCancel;

  @override
  State<_ImportPassphraseDialog> createState() =>
      _ImportPassphraseDialogState();
}

class _ImportPassphraseDialogState extends State<_ImportPassphraseDialog> {
  final _passphrase = TextEditingController();

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _passphrase.text;
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.backupImportPassphraseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.backupImportPassphraseBody),
          TextField(
            controller: _passphrase,
            autofocus: true,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
          child: Text(loc.backupPassphraseCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(loc.backupPassphraseConfirm),
        ),
      ],
    );
  }
}
