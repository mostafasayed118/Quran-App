import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/download_status.dart';
import '../../domain/reciter_info.dart';
import '../downloads/downloads_cubit.dart';
import '../downloads/downloads_state.dart';
import '../playback/playback_cubit.dart';
import '../playback/mini_player_bar.dart';
import 'reciter_surahs_cubit.dart';
import 'reciter_surahs_state.dart';

class ReciterSurahsScreen extends StatelessWidget {
  const ReciterSurahsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ReciterSurahsCubit, ReciterSurahsState>(
          builder: (context, state) => switch (state) {
            ReciterSurahsReady(:final row) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.reciterName,
                    style: AppTheme.rowTitle,
                  ),
                  Text(
                    row.moshafName,
                    style: AppTheme.mutedFootnote(context),
                  ),
                ],
              ),
            _ => Text(loc.recitationsTitle),
          },
        ),
        actions: [
          IconButton(
            tooltip: loc.featured,
            icon: const Icon(Icons.star_border),
            onPressed: () => _setDefault(context),
          ),
        ],
      ),
      body: BlocBuilder<ReciterSurahsCubit, ReciterSurahsState>(
        builder: (context, state) => switch (state) {
          ReciterSurahsLoading() => const LoadingView(),
          ReciterSurahsError() => errorPane(loc),
          ReciterSurahsReady(
            :final row,
            :final surahNumbers,
            :final names,
            :final previews,
          ) =>
            BlocBuilder<DownloadsCubit, DownloadsState>(
              builder: (context, dl) => ListView.builder(
                itemCount: surahNumbers.length,
                itemBuilder: (context, i) {
                  final n = surahNumbers[i];
                  return _SurahDownloadRow(
                    reciter: row,
                    surahNumber: n,
                    name: names[n] ?? loc.surahFallbackName(n.toArabicIndic),
                    teaser: previews[n],
                    item: dl.items['${row.id}-$n'],
                  );
                },
              ),
            ),
        },
      ),
      bottomSheet: const MiniPlayerBar(),
    );
  }

  Future<void> _setDefault(BuildContext context) async {
    await context.read<ReciterSurahsCubit>().setAsDefault();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).defaultReciterSet),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class _SurahDownloadRow extends StatelessWidget {
  const _SurahDownloadRow({
    required this.reciter,
    required this.surahNumber,
    required this.name,
    this.teaser,
    this.item,
  });

  final ReciterInfo reciter;
  final int surahNumber;
  final String name;
  final String? teaser;
  final DownloadItem? item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<DownloadsCubit>();
    final status = item?.status;
    return ListTile(
      contentPadding: AppTheme.tileContentPadding,
      leading: _buildLeading(context, colors),
      title: Text(
        name,
        style: AppTheme.meQuranHead,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: teaser == null || teaser!.isEmpty
          ? null
          : Text(
              teaser!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: QuranFonts.meQuran,
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
      trailing: _buildTrailing(context, cubit, colors, status),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DownloadsCubit cubit) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.libraryDelete,
      body: name,
    );
    if (confirmed) {
      await cubit.removeDone(reciter.id, surahNumber);
    }
  }

  Widget _buildLeading(BuildContext context, ColorScheme colors) {
    return IconButton(
      tooltip: AppLocalizations.of(context).playTooltip,
      icon: Icon(Icons.play_arrow, color: colors.primary),
      onPressed: () => context.read<PlaybackCubit>().playReciter(
            reciter,
            surahNumber,
          ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    DownloadsCubit cubit,
    ColorScheme colors,
    DownloadStatus? status,
  ) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case DownloadStatus.done:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: colors.secondary, width: 1.5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.check, color: colors.secondary, size: 20),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).libraryDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, cubit),
            ),
          ],
        );
      case DownloadStatus.downloading:
        final item = this.item!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DownloadProgress(received: item.received, total: item.total),
            _CancelDownloadButton(
              onPressed: () => cubit.cancelDownload(reciter.id, surahNumber),
            ),
          ],
        );
      case DownloadStatus.failed:
        return IconButton(
          tooltip: loc.retry,
          color: colors.error,
          icon: const Icon(Icons.refresh),
          onPressed: () => cubit.enqueue(reciter.id, surahNumber),
        );
      case DownloadStatus.queued:
        return _CancelDownloadButton(
          onPressed: () => cubit.cancelDownload(reciter.id, surahNumber),
        );
      case null:
        return IconButton(
          tooltip: loc.downloadSurah,
          icon: const Icon(Icons.download),
          onPressed: () => cubit.enqueue(reciter.id, surahNumber),
        );
    }
  }
}

class _CancelDownloadButton extends StatelessWidget {
  const _CancelDownloadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).cancel,
      icon: const Icon(Icons.close),
      onPressed: onPressed,
    );
  }
}

/// Compact in-flight progress for a surah row: one-line label over a thin
/// bar. The shared `DownloadProgressLabel` stacks an unbounded Text inside
/// ListTile's height-bound trailing slot, which overflows at textScale 2.0;
/// here the label ellipsizes and the bar keeps the truthful progress picture.
class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.received, required this.total});

  final int received;
  final int total;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            downloadProgressLabel(loc, received, total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mutedFootnote(context),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? (received / total).clamp(0.0, 1.0) : null,
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

/// One-decimal MB label with Arabic-Indic digits (recitation surfaces).
/// A non-positive [total] means the server never declared a size: the
/// received amount renders alone.
@visibleForTesting
String downloadProgressLabel(AppLocalizations loc, int received, int total) {
  final receivedLabel = _megabytes(received).toArabicIndicDigits;
  if (total <= 0) return loc.downloadProgressReceived(receivedLabel);
  return loc.downloadProgressOfTotal(
      receivedLabel, _megabytes(total).toArabicIndicDigits);
}

String _megabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
