import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/juz_summary.dart';
import 'juz_index_cubit.dart';
import 'juz_index_state.dart';

/// The 30 juz starts without a Scaffold, shared by the compact screen and the
/// workspace master pane.
class JuzIndexBody extends StatelessWidget {
  /// Creates the body; [onSelect] replaces the route push in the workspace.
  const JuzIndexBody({super.key, required this.onSelect, this.selectedJuz});

  /// Called with the tapped juz.
  final ValueChanged<JuzSummary> onSelect;

  /// The highlighted juz, when a pane is open.
  final int? selectedJuz;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<JuzIndexCubit>();
    return BlocBuilder<JuzIndexCubit, JuzIndexState>(
      builder: (context, state) => switch (state) {
        JuzIndexLoading() => const LoadingView(),
        JuzIndexFailed() => errorPane(loc, onRetry: cubit.start),
        JuzIndexReady(:final juz) when juz.isEmpty => EmptyState(loc.noResults),
        JuzIndexReady(:final juz) => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: juz.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = juz[index];
              return ListTile(
                selected: entry.juz == selectedJuz,
                leading: CircleAvatar(
                  child: Text(loc.number(entry.juz)),
                ),
                title: Text(loc.juzLabel(loc.number(entry.juz))),
                subtitle: Text(
                  '${entry.surahName} · ${loc.number(entry.firstPage)}',
                ),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => onSelect(entry),
              );
            },
          ),
      },
    );
  }
}
