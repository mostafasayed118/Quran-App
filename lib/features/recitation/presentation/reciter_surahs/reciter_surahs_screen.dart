import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../downloads/downloads_cubit.dart';
import '../downloads/downloads_state.dart';
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
          ReciterSurahsLoading() =>
            const Center(child: CircularProgressIndicator()),
          ReciterSurahsError(:final message) => Center(child: Text(message)),
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
                    rowId: row.id,
                    surahNumber: n,
                    name: names[n] ?? 'سورة ${n.toArabicIndic}',
                    teaser: previews[n],
                    item: dl.items['${row.id}-$n'],
                  );
                },
              ),
            ),
        },
      ),
    );
  }

  Future<void> _setDefault(BuildContext context) async {
    await context.read<ReciterSurahsCubit>().setAsDefault();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تعيينه قارئك الافتراضي'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class _SurahDownloadRow extends StatelessWidget {
  const _SurahDownloadRow({
    required this.rowId,
    required this.surahNumber,
    required this.name,
    this.teaser,
    this.item,
  });

  final String rowId;
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
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          surahNumber.toArabicIndic,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontFamily: QuranFonts.meQuran, fontSize: 20),
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

  Widget _buildTrailing(
    BuildContext context,
    DownloadsCubit cubit,
    ColorScheme colors,
    String status,
  ) {
    switch (status) {
      case 'done':
        return Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colors.secondary, width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.check, color: colors.secondary, size: 20),
        );
      case 'downloading':
        final item = this.item!;
        final progress = item.total > 0 ? item.received / item.total : null;
        return SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.received}/${item.total}',
                style: TextStyle(
                    fontSize: 11, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress),
            ],
          ),
        );
      case 'failed':
        return IconButton(
          tooltip: MaterialLocalizations.of(context)
              .refreshIndicatorSemanticLabel,
          color: colors.error,
          icon: const Icon(Icons.refresh),
          onPressed: () => cubit.enqueue(rowId, surahNumber),
        );
      default:
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => cubit.enqueue(rowId, surahNumber),
        );
    }
  }
}
