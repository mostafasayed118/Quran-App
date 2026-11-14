import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/azkar_repository.dart';
import 'azkar_cubit.dart';
import 'azkar_state.dart';

part 'azkar_browse.dart';
part 'azkar_recite.dart';

/// Whether the azkar scaffold must rebuild for [current].
///
/// A counter tap (or a restart) emits the same reciting collection with new
/// `remaining` values; the rows own that (each card selects its own counter),
/// so rebuilding the whole scaffold per tap is pure cost. Every other
/// transition — a new session, browsing, a search result, a failure — rebuilds.
bool azkarScreenShouldRebuild(AzkarState previous, AzkarState current) {
  if (previous.runtimeType != current.runtimeType) return true;
  if (previous is AzkarReciting && current is AzkarReciting) {
    return !identical(previous.collection, current.collection);
  }
  return true;
}

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
      buildWhen: azkarScreenShouldRebuild,
      builder: (context, state) {
        final reciting = state is AzkarReciting;
        return PopScope(
          canPop: !reciting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && reciting) {
              context.read<AzkarCubit>().back();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const _AzkarTitle(),
              leading: const _AzkarBackButton(),
              actions: [
                if (reciting)
                  IconButton(
                    tooltip: loc.azkarRestart,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: context.read<AzkarCubit>().restart,
                  ),
              ],
            ),
            body: AppContentFrame(
              child: switch (state) {
                AzkarLoading() => const LoadingView(),
                AzkarFailed() =>
                  errorPane(loc, onRetry: context.read<AzkarCubit>().start),
                AzkarBrowsing(
                  :final collections,
                  :final favorites,
                  :final query,
                  :final searchResults,
                  :final searchHasMore,
                ) =>
                  _BrowsingView(
                    collections: collections,
                    favorites: favorites,
                    query: query,
                    searchResults: searchResults,
                    searchHasMore: searchHasMore,
                  ),
                AzkarReciting(:final collection) =>
                  _RecitingList(collection: collection),
              },
            ),
          ),
        );
      },
    );
  }
}
