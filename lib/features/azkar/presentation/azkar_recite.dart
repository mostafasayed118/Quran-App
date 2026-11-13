part of 'azkar_screen.dart';

class _RecitingList extends StatelessWidget {
  const _RecitingList({required this.collection});

  /// The open session's collection — stable while counting, so the list itself
  /// is built once and each row subscribes to its own counter.
  final AzkarCollection collection;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: appScrollPadding(
        context,
        const EdgeInsets.all(AppSpacing.md),
      ),
      itemCount: collection.items.length,
      itemBuilder: (context, i) {
        final item = collection.items[i];
        // Per-row selector: a tap re-emits the whole state, but only the row
        // whose counter changed rebuilds.
        return BlocSelector<AzkarCubit, AzkarState, int>(
          selector: (state) =>
              state is AzkarReciting && i < state.remaining.length
                  ? state.remaining[i]
                  : item.count,
          builder: (context, remaining) =>
              _RecitingCard(item: item, remaining: remaining, index: i),
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
      // 0.45 dropped the completed body text to ~2.6:1. 0.8 keeps a clear
      // "done" affordance while the text remains readable.
      opacity: done ? 0.8 : 1,
      child: Card(
        color: done ? colors.surfaceContainerHighest : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: done
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  context.read<AzkarCubit>().tapItem(index);
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ZikrLine(item: item, remaining: remaining, done: done),
                if (item.virtue != null || item.reference != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      [
                        if (item.virtue case final virtue?) virtue,
                        if (item.reference case final reference?) reference,
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
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.text,
            textAlign: TextAlign.right,
            // Long-form dhikr prose reads in the UI face; the mushaf face is
            // for Quran text (its word spacing and kashida suit a page).
            style: const TextStyle(
              fontFamily: QuranFonts.ui,
              fontSize: 17,
              height: 2.1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
                  loc.number(remaining),
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
