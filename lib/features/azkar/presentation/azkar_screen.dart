import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'azkar_cubit.dart';
import 'azkar_state.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AzkarCubit, AzkarState>(
          builder: (context, state) => switch (state) {
            AzkarReciting(:final collection) => Text(collection.nameAr),
            _ => Text(loc.azkar),
          },
        ),
        leading: BlocBuilder<AzkarCubit, AzkarState>(
          builder: (context, state) {
            final reciting = state is AzkarReciting;
            return IconButton(
              tooltip: loc.backTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (reciting) {
                  context.read<AzkarCubit>().back();
                } else {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ),
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) => switch (state) {
          AzkarLoading() => const LoadingView(),
          AzkarFailed() => errorPane(loc, 'azkar load failed', 'azkar'),
          AzkarBrowsing(:final collections) => collections.isEmpty
              ? EmptyState(loc.noResults)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: collections.length,
                  itemBuilder: (context, i) {
                    final collection = collections[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          collection.nameAr,
                          style: const TextStyle(
                            fontFamily: QuranFonts.meQuran,
                            fontSize: 19,
                          ),
                        ),
                        subtitle: Text(collection.nameEn),
                        trailing: Text(
                          loc.azkarItemsCount(
                              collection.items.length.toArabicIndic),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () =>
                            context.read<AzkarCubit>().open(collection),
                      ),
                    );
                  },
                ),
          AzkarReciting() => const _RecitingList(),
        },
      ),
    );
  }
}

class _RecitingList extends StatelessWidget {
  const _RecitingList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) {
        final reciting = state as AzkarReciting;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reciting.collection.items.length,
          itemBuilder: (context, i) {
            final item = reciting.collection.items[i];
            final remaining = reciting.remaining[i];
            final done = remaining == 0;
            final colors = Theme.of(context).colorScheme;
            return Opacity(
              opacity: done ? 0.45 : 1,
              child: Card(
                color: done ? colors.surfaceContainerHighest : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: done
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          context.read<AzkarCubit>().tapItem(i);
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.text,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: QuranFonts.meQuran,
                                  fontSize: 18,
                                  height: 1.9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: done
                                    ? colors.secondary
                                    : colors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: done
                                  ? const Icon(Icons.check, size: 20)
                                  : Text(
                                      remaining.toArabicIndic,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colors.onPrimaryContainer,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        if (item.virtue != null || item.reference != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              [
                                if (item.virtue != null) item.virtue!,
                                if (item.reference != null) item.reference!,
                              ].join(' · '),
                              textAlign: TextAlign.right,
                              style: AppTheme.mutedFootnote(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
