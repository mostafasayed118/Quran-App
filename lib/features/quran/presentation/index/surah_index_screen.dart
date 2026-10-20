import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/surah_summary.dart';
import 'surah_index_cubit.dart';
import 'surah_index_state.dart';

class SurahIndexScreen extends StatelessWidget {
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.surahIndexTitle)),
      body: BlocBuilder<SurahIndexCubit, SurahIndexState>(
        builder: (context, state) => switch (state) {
          SurahIndexLoading() => const LoadingView(),
          SurahIndexFailed() => errorPane(loc),
          SurahIndexReady(:final surahs) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                  child: SearchField(
                    hint: loc.searchSurahHint,
                    onChanged: context.read<SurahIndexCubit>().setQuery,
                  ),
                ),
                Expanded(
                  child: surahs.isEmpty
                      ? EmptyState(loc.noResults)
                      : ListView.builder(
                          itemCount: surahs.length,
                          itemBuilder: (context, i) =>
                              _SurahRow(surah: surahs[i]),
                        ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah});

  final SurahSummary surah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isMakkah = surah.revelationType == 'makkah';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () => context.push('/quran/reader?surah=${surah.id}&ayah=0'),
      leading: ArabicBadge(surah.id.toArabicIndic),
      title: Text(
        surah.nameAr,
        style: AppTheme.meQuranHead,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${isMakkah ? loc.revelationMakkah : loc.revelationMadinah} · ${loc.ayatCount(surah.ayahCount).toArabicIndicDigits}',
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.right,
      ),
      trailing: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left
            : Icons.chevron_right,
      ),
    );
  }
}
