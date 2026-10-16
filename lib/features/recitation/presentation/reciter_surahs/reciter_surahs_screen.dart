import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/download_progress.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/recitation/data/reciter_repository.dart';
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
                    style: const TextStyle(
                      fontFamily: QuranFonts.ui,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
          ReciterSurahsError(:final message) =>
            _errorPane(loc, message, 'reciter_surahs'),
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

  final ReciterRow reciter;
  final int surahNumber;
  final String name;
  final String? teaser;
  final DownloadItem? item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<DownloadsCubit>();
    final status = item?.status ?? 'none';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.libraryDelete),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.libraryDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.removeDone(reciter.id, surahNumber);
    }
  }

  Widget _buildLeading(BuildContext context, ColorScheme colors) {
    if (!parseSurahList(reciter.surahList).contains(surahNumber)) {
      return ArabicBadge(surahNumber.toArabicIndic);
    }
    return IconButton(
      tooltip: AppLocalizations.of(context).playTooltip,
      icon: Icon(Icons.play_arrow, color: colors.primary),
      onPressed: () => context.read<PlaybackCubit>().playSurah(
            reciter,
            surahNumber,
          ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    DownloadsCubit cubit,
    ColorScheme colors,
    String status,
  ) {
    switch (status) {
      case 'done':
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
      case 'downloading':
        final item = this.item!;
        return DownloadProgressLabel(
          received: item.received,
          total: item.total,
          width: 96,
          gap: 4,
          labelStyle: AppTheme.mutedFootnote(context),
        );
      case 'failed':
        return IconButton(
          tooltip: MaterialLocalizations.of(context)
              .refreshIndicatorSemanticLabel,
          color: colors.error,
          icon: const Icon(Icons.refresh),
          onPressed: () => cubit.enqueue(reciter.id, surahNumber),
        );
      default:
        return IconButton(
          tooltip: AppLocalizations.of(context).downloadSurah,
          icon: const Icon(Icons.download),
          onPressed: () => cubit.enqueue(reciter.id, surahNumber),
        );
    }
  }
}

Widget _errorPane(AppLocalizations loc, String message, String source) {
  dev.log(message, name: 'quran_yahdi/$source');
  return ErrorView(loc.genericError);
}
