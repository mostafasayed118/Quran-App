import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/surah_summary.dart';
import 'surah_index_cubit.dart';
import 'surah_index_state.dart';

/// The surah list without its Scaffold, so the compact screen and the
/// workspace master pane share one implementation.
class SurahIndexBody extends StatelessWidget {
  /// Creates the body; [onSelect] replaces the route push in the workspace.
  const SurahIndexBody({
    super.key,
    required this.onSelect,
    this.selectedSurahId,
  });

  /// Called with the tapped surah.
  final ValueChanged<SurahSummary> onSelect;

  /// The highlighted surah, when a pane is open.
  final int? selectedSurahId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<SurahIndexCubit>();
    return BlocBuilder<SurahIndexCubit, SurahIndexState>(
      builder: (context, state) => switch (state) {
        SurahIndexLoading() => const LoadingView(),
        SurahIndexFailed() => errorPane(loc, onRetry: cubit.reload),
        SurahIndexReady(:final surahs, :final query) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: SearchField(
                  hint: loc.searchSurahHint,
                  onChanged: context.read<SurahIndexCubit>().setQuery,
                ),
              ),
              Expanded(
                child: surahs.isEmpty
                    ? (query.isEmpty
                        ? EmptyState(loc.noResults)
                        : EmptyState(
                            loc.noResults,
                            // The typed words matched no surah name: offer
                            // the verse search for the same words instead
                            // of a dead end.
                            actionLabel: loc.searchAyahsFor(query),
                            onAction: () =>
                                context.push(quranSearchPath(query: query)),
                          ))
                    : ListView.builder(
                        padding:
                            EdgeInsets.only(bottom: appBottomInset(context)),
                        itemCount: surahs.length,
                        itemBuilder: (context, i) => _SurahRow(
                          surah: surahs[i],
                          selected: surahs[i].id == selectedSurahId,
                          onTap: () => onSelect(surahs[i]),
                        ),
                      ),
              ),
            ],
          ),
      },
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.selected,
    required this.onTap,
  });

  final SurahSummary surah;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isMakkah = surah.isMakkah;
    return ListTile(
      selected: selected,
      contentPadding: AppTheme.tileContentPadding,
      onTap: onTap,
      leading: ArabicBadge(loc.number(surah.id)),
      title: Text(
        surah.nameAr,
        style: AppTheme.meQuranHead,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${isMakkah ? loc.revelationMakkah : loc.revelationMadinah} · ${loc.digits(loc.ayatCount(surah.ayahCount))}',
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.start,
      ),
      trailing: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left
            : Icons.chevron_right,
      ),
    );
  }
}
