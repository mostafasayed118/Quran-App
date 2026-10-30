import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/error_strip.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/reciter_mapping.dart';
import '../../domain/reciter_info.dart';
import 'reciters_cubit.dart';
import 'reciters_state.dart';

class RecitersScreen extends StatelessWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recitationsTitle),
        actions: [
          IconButton(
            tooltip: loc.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecitersCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<RecitersCubit, RecitersState>(
        builder: (context, state) => switch (state) {
          RecitersLoading() => const LoadingView(),
          RecitersFailed() => errorPane(loc),
          RecitersReady(:final reciters, :final query, :final dataError) =>
            Column(
              children: [
                if (dataError)
                  ErrorStrip(
                    loc.recitersRefreshFailed,
                    icon: Icons.wifi_off,
                    onDismiss: () =>
                        context.read<RecitersCubit>().clearDataError(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                  child: SearchField(
                    hint: loc.searchReciters,
                    onChanged: context.read<RecitersCubit>().setQuery,
                  ),
                ),
                Expanded(
                  child: reciters.isEmpty
                      ? EmptyState(
                          query.isEmpty ? loc.noReciters : loc.noResults,
                          actionLabel: query.isEmpty ? loc.refresh : null,
                          onAction: query.isEmpty
                              ? () => context.read<RecitersCubit>().refresh()
                              : null,
                        )
                      : _RecitersList(reciters: reciters),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _ReciterEntry {
  const _ReciterEntry(this.row, this.showTitle);

  final ReciterInfo row;
  final bool showTitle;
}

class _RecitersList extends StatelessWidget {
  const _RecitersList({required this.reciters});

  final List<ReciterInfo> reciters;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // Lightweight entries (headers + rows) built once per state; the heavy
    // ListTile widgets now render lazily through the builder.
    final entries = <Object>[];
    var featuredHeaderDone = false;
    var allHeaderDone = false;
    // A reciter with several moshafs spans several rows: print the name once
    // and let the repeated rows read as its moshaf variants.
    String? lastRowName;
    for (final row in reciters) {
      final featured = isFeaturedReciterInfo(row);
      if (featured && !featuredHeaderDone) {
        entries.add(loc.featured);
        featuredHeaderDone = true;
        lastRowName = null;
      }
      if (!featured && !allHeaderDone) {
        entries.add(loc.allReciters);
        allHeaderDone = true;
        lastRowName = null;
      }
      final trimmed = row.reciterName.trim();
      entries.add(_ReciterEntry(row, trimmed != lastRowName));
      lastRowName = trimmed;
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        final String title => SectionHeader(title: title),
        final _ReciterEntry entry =>
          _ReciterRow(reciter: entry.row, showTitle: entry.showTitle),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ReciterRow extends StatelessWidget {
  const _ReciterRow({required this.reciter, required this.showTitle});

  final ReciterInfo reciter;

  /// False for the 2nd..nth moshaf of the same reciter: the name is already
  /// printed on the row above, so this row leads with the moshaf.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trimmed = reciter.reciterName.trim();
    final initial = trimmed.isEmpty
        ? loc.unknownInitial
        : String.fromCharCode(trimmed.runes.first);
    return ListTile(
      contentPadding: AppTheme.tileContentPadding,
      onTap: () => context.push(reciterSurahsPath(reciter.id)),
      leading: ArabicBadge(
        initial,
        textStyle: const TextStyle(fontSize: 16),
      ),
      title: Text(
        showTitle ? reciter.reciterName : reciter.moshafName,
        style: showTitle
            ? AppTheme.rowTitle
            : const TextStyle(fontWeight: FontWeight.w500),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: showTitle
          ? Text(
              reciter.moshafName,
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.right,
            )
          : null,
      trailing: Text(
        loc.surahCountLabel(reciter.surahTotal.toArabicIndic),
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}
