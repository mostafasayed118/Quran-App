import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/insets.dart';
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
  late Future<List<InstalledDownload>> _installed;

  @override
  void initState() {
    super.initState();
    _installed = _read();
  }

  Future<List<InstalledDownload>> _read() =>
      context.read<DownloadsCubit>().installed();

  /// Re-reads after a delete or a retry. The builder renders the new future's
  /// loading arm, so the list never shows a stale row mid-refresh.
  void _reload() {
    setState(() {
      _installed = _read();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.genericError)),
      );
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.downloadsTitle)),
      body: FutureBuilder<List<InstalledDownload>>(
        future: _installed,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) return errorPane(loc, onRetry: _reload);
          final items = snapshot.data ?? const <InstalledDownload>[];
          if (items.isEmpty) {
            return EmptyState(
              loc.downloadsEmpty,
              icon: Icons.download_done_outlined,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: appBottomInset(context)),
            itemCount: items.length,
            itemBuilder: (context, i) => _DownloadRow(
              item: items[i],
              onDelete: () => _delete(items[i]),
            ),
          );
        },
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
        ? loc.surahFallbackName(item.surahNumber.toArabicIndic)
        : item.surahName;
    // The pack size is the app's existing "{size} MB" template; a downloaded
    // surah is sized the same way.
    final size = loc.libraryPackSize(
      formatMegabytes(item.bytes).toArabicIndicDigits,
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
