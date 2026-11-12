part of 'bookmarks_body.dart';

class _BookmarkList extends StatelessWidget {
  const _BookmarkList({
    required this.state,
    required this.meta,
    required this.canEdit,
    required this.onSelect,
    this.selectedAyahId,
  });

  final BookmarksReady state;
  final Map<int, BookmarkMetaEntry> meta;
  final bool canEdit;
  final ValueChanged<Verse> onSelect;
  final int? selectedAyahId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final showTail = state.hasMore || state.loadingMore || state.moreFailed;
    final entries = state.entries;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          context.read<BookmarksCubit>().loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: appBottomInset(context)),
        itemCount: entries.length + (showTail ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == entries.length) return _tail(context, loc);
          final ayah = entries[index];
          final entry = meta[ayah.id];
          final hasMeta = entry != null && !entry.isEmpty;
          return ListTile(
            selected: ayah.id == selectedAyahId,
            leading: Text(
              '${loc.number(ayah.surahId)}:${loc.number(ayah.numberInSurah)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            title: Text(
              ayah.textImlaei,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: hasMeta ? _MetaLine(entry: entry) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  IconButton(
                    tooltip: loc.bookmarkEdit,
                    icon: const Icon(Icons.edit_note),
                    onPressed: () => _editMeta(context, ayah, entry),
                  ),
                IconButton(
                  tooltip: loc.bookmarkRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmRemove(context, ayah.id, loc),
                ),
              ],
            ),
            onTap: () => onSelect(ayah),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, int ayahId, AppLocalizations loc) async {
    // The cubit is resolved before the await so the confirmation cannot
    // outlive the provider lookup.
    final cubit = context.read<BookmarksCubit>();
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.bookmarkRemove,
      body: loc.bookmarkRemoveBody,
    );
    if (!context.mounted || !confirmed) return;
    final removed = await cubit.remove(ayahId);
    if (!context.mounted) return;
    AppToast.show(
      context,
      removed ? loc.bookmarkRemoved : loc.genericError,
      tone: removed ? ToastTone.success : ToastTone.error,
    );
  }

  Future<void> _editMeta(
    BuildContext context,
    Verse ayah,
    BookmarkMetaEntry? current,
  ) async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<BookmarkMetaCubit>();
    final result = await showDialog<({String folder, String note})>(
      context: context,
      builder: (_) => _BookmarkMetaDialog(
        folder: current?.folder ?? '',
        note: current?.note ?? '',
      ),
    );
    if (result == null) return;
    final ok = await cubit.set(
      ayah.id,
      folder: result.folder,
      note: result.note,
    );
    if (!ok && context.mounted) {
      AppToast.show(context, loc.genericError, tone: ToastTone.error);
    }
  }

  Widget _tail(BuildContext context, AppLocalizations loc) {
    if (state.moreFailed) {
      return Center(
        child: TextButton(
          onPressed: context.read<BookmarksCubit>().retryMore,
          child: Text(loc.retry),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
