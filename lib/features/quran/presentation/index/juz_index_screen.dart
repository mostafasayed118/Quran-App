import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../l10n/app_localizations.dart';
import 'juz_index_cubit.dart';
import 'juz_index_state.dart';

/// The 30 juz starts, each opening the reader at its first ayah.
class JuzIndexScreen extends StatelessWidget {
  /// Creates the screen.
  const JuzIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<JuzIndexCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.juzIndexTitle)),
      body: BlocBuilder<JuzIndexCubit, JuzIndexState>(
        builder: (context, state) => switch (state) {
          JuzIndexLoading() => const LoadingView(),
          JuzIndexFailed() => errorPane(loc, onRetry: cubit.start),
          JuzIndexReady(:final juz) when juz.isEmpty =>
            EmptyState(loc.noResults),
          JuzIndexReady(:final juz) => ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: juz.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = juz[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(loc.number(entry.juz)),
                  ),
                  title: Text(loc.juzLabel(loc.number(entry.juz))),
                  subtitle: Text(
                    '${entry.surahName} · ${loc.number(entry.firstPage)}',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(
                    quranReaderPath(
                      surah: entry.surahId,
                      ayah: entry.numberInSurah,
                    ),
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}
