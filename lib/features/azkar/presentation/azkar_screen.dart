import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/azkar_repository.dart';
import 'azkar_cubit.dart';
import 'azkar_state.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const _AzkarTitle(),
        leading: const _AzkarBackButton(),
      ),
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) => switch (state) {
          AzkarLoading() => const LoadingView(),
          AzkarFailed() => errorPane(loc),
          AzkarBrowsing(:final collections) =>
            _BrowsingView(collections: collections),
          AzkarReciting() => const _RecitingList(),
        },
      ),
    );
  }
}

class _AzkarTitle extends StatelessWidget {
  const _AzkarTitle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) => switch (state) {
        AzkarReciting(:final collection) => Text(collection.nameAr),
        _ => Text(loc.azkar),
      },
    );
  }
}

class _AzkarBackButton extends StatelessWidget {
  const _AzkarBackButton();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
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
    );
  }
}

class _BrowsingView extends StatelessWidget {
  const _BrowsingView({required this.collections});

  final List<AzkarCollection> collections;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return collections.isEmpty
        ? EmptyState(loc.noResults)
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: collections.length,
            itemBuilder: (context, i) =>
                _CollectionTile(collection: collections[i]),
          );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final AzkarCollection collection;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          loc.azkarItemsCount(collection.items.length.toArabicIndic),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => context.read<AzkarCubit>().open(collection),
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
            return _RecitingCard(item: item, remaining: remaining, index: i);
          },
        );
      },
    );
  }
}

class _RecitingCard extends StatelessWidget {
  const _RecitingCard({
    required this.item,
    required this.remaining,
    required this.index,
  });

  final AzkarItem item;
  final int remaining;
  final int index;

  @override
  Widget build(BuildContext context) {
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
                  context.read<AzkarCubit>().tapItem(index);
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ZikrLine(item: item, remaining: remaining, done: done),
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
  }
}

class _ZikrLine extends StatelessWidget {
  const _ZikrLine({
    required this.item,
    required this.remaining,
    required this.done,
  });

  final AzkarItem item;
  final int remaining;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
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
            color: done ? colors.secondary : colors.primaryContainer,
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
    );
  }
}
