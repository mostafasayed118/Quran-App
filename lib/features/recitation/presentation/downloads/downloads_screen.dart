import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'downloads_cubit.dart';

/// The installed downloads list: one row per downloaded surah.
///
/// Read-only surface for now — a row names the reciter, the surah and the
/// file size, and can delete the file. Playback does not start here.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<_DownloadsView> _data;

  @override
  void initState() {
    super.initState();
    _data = _read();
  }

  Future<_DownloadsView> _read() => _load(context.read<DownloadsCubit>());

  static Future<_DownloadsView> _load(DownloadsCubit cubit) async {
    final items = await cubit.installed();
    final summary = await cubit.summary();
    return _DownloadsView(items: items, summary: summary);
  }

  /// Re-reads after a delete or a retry. The builder renders the new future's
  /// loading arm, so the list never shows a stale row mid-refresh.
  void _reload() {
    setState(() {
      _data = _read();
    });
  }

  Future<void> _delete(InstalledDownload item) async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<DownloadsCubit>();
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.libraryDelete,
      body: loc.downloadsDeleteBody,
    );
    if (!confirmed) return;
    final removed = await cubit.removeDone(item.rowId, item.surahNumber);
    if (!mounted) return;
    if (!removed) {
      AppToast.show(context, loc.genericError, tone: ToastTone.error);
      return;
    }
    _reload();
    AppToast.show(context, loc.downloadDeleted, tone: ToastTone.success);
  }

  /// Deletes every installed download. A failure replaces the future, so the
  /// builder shows its error pane with the retry — the rows removed before the
  /// failure are already gone, and the retry re-reads what is left.
  Future<void> _deleteAll() async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<DownloadsCubit>();
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.downloadsDeleteAll,
      body: loc.downloadsDeleteAllBody,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final future = _removeAllThenRead(cubit);
    setState(() {
      _data = future;
    });
    try {
      await future;
    } on Object {
      // The builder renders this future's error pane; a toast would only
      // repeat what the pane already says.
      return;
    }
    AppToast.showOn(
      messenger,
      loc.downloadsDeletedAll,
      tone: ToastTone.success,
    );
  }

  static Future<_DownloadsView> _removeAllThenRead(DownloadsCubit cubit) async {
    await cubit.removeAll();
    return _load(cubit);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.downloadsTitle)),
      body: AppContentFrame(
        child: FutureBuilder<_DownloadsView>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView();
            }
            if (snapshot.hasError) return errorPane(loc, onRetry: _reload);
            final view = snapshot.data;
            if (view == null || view.items.isEmpty) {
              return EmptyState(
                loc.downloadsEmpty,
                icon: Icons.download_done_outlined,
              );
            }
            return Column(
              children: [
                // The header is a Card, never a ListTile: the list rows own that
                // type. It appears only from two rows up, where a total and a
                // "delete all" are worth the space.
                if (view.summary.count >= 2)
                  _SummaryHeader(
                    summary: view.summary,
                    onDeleteAll: _deleteAll,
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: appBottomInset(context)),
                    itemCount: view.items.length,
                    itemBuilder: (context, i) => _DownloadRow(
                      item: view.items[i],
                      onDelete: () => _delete(view.items[i]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One load of the screen: the rows and the aggregate the header shows.
class _DownloadsView {
  const _DownloadsView({required this.items, required this.summary});

  final List<InstalledDownload> items;
  final DownloadsSummary summary;
}

/// The storage header above the list: total size, file count and the
/// delete-all action.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary, required this.onDeleteAll});

  final DownloadsSummary summary;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.sd_storage_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.downloadsTotal(
                      loc.digits(formatMegabytes(summary.bytes)),
                    ),
                    style: AppTheme.cardTitle,
                  ),
                  Text(
                    loc.downloadsCount(loc.number(summary.count)),
                    style: AppTheme.caption
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDeleteAll,
              child: Text(loc.downloadsDeleteAll),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.item, required this.onDelete});

  final InstalledDownload item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final surahName = item.surahName.isEmpty
        ? loc.surahFallbackName(loc.number(item.surahNumber))
        : item.surahName;
    // The pack size is the app's existing "{size} MB" template; a downloaded
    // surah is sized the same way.
    final size = loc.libraryPackSize(
      loc.digits(formatMegabytes(item.bytes)),
    );
    final reciterName = item.reciterName;
    final subtitle = reciterName.isEmpty ? size : '$reciterName · $size';
    return ListTile(
      contentPadding: AppTheme.tileContentPadding,
      leading: Icon(Icons.download_done, color: colors.primary),
      title: Text(
        surahName,
        style: AppTheme.cardTitle,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.caption.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      trailing: IconButton(
        tooltip: loc.libraryDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
