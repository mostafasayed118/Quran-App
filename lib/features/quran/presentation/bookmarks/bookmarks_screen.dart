import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/bookmark_meta.dart';
import '../../domain/verse.dart';
import 'bookmark_meta_cubit.dart';
import 'bookmark_meta_state.dart';
import 'bookmarks_cubit.dart';
import 'bookmarks_state.dart';

class BookmarksScreen extends StatelessWidget {
  /// Creates the screen.
  ///
  /// [showMeta] opts into the folder chips and the note/folder editor; the
  /// route supplies the [BookmarkMetaCubit] then. Tests that only exercise the
  /// bookmark list keep the default and need no meta provider.
  const BookmarksScreen({super.key, this.showMeta = false});

  /// Whether the folder/note layer is rendered.
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) => switch (state) {
        BookmarksLoading() => const Scaffold(body: LoadingView()),
        BookmarksFailed() => Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).bookmarks)),
            body: errorPane(AppLocalizations.of(context)),
          ),
        BookmarksReady() => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).bookmarks),
            ),
            body: state.entries.isEmpty
                ? EmptyState(
                    AppLocalizations.of(context).noBookmarks,
                    actionLabel: AppLocalizations.of(context).quran,
                    onAction: () => context.push(AppRoutes.quran),
                  )
                : _body(context, state),
          ),
      },
    );
  }

  Widget _body(BuildContext context, BookmarksReady state) {
    if (!showMeta) {
      return _BookmarkList(
        state: state,
        meta: const <int, BookmarkMetaEntry>{},
        canEdit: false,
      );
    }
    return BlocBuilder<BookmarkMetaCubit, BookmarkMetaState>(
      builder: (context, metaState) {
        final meta = metaState is BookmarkMetaReady
            ? metaState.entries
            : const <int, BookmarkMetaEntry>{};
        final folders = metaState is BookmarkMetaReady
            ? metaState.folders
            : const <String>[];
        return Column(
          children: [
            if (folders.isNotEmpty) _FolderChips(folders: folders),
            Expanded(
              child: _BookmarkList(
                state: state,
                meta: meta,
                canEdit: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FolderChips extends StatelessWidget {
  const _FolderChips({required this.folders});

  final List<String> folders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final folder in folders)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: ActionChip(
                avatar: const Icon(Icons.folder_outlined, size: 16),
                label: Text(folder),
                onPressed: () => context.push(bookmarksFolderPath(folder)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  const _BookmarkList({
    required this.state,
    required this.meta,
    required this.canEdit,
  });

  final BookmarksReady state;
  final Map<int, BookmarkMetaEntry> meta;
  final bool canEdit;

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
            onTap: () => context.push(quranReaderPath(
              surah: ayah.surahId,
              ayah: ayah.numberInSurah,
            )),
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

class _BookmarkMetaDialog extends StatefulWidget {
  const _BookmarkMetaDialog({required this.folder, required this.note});

  final String folder;
  final String note;

  @override
  State<_BookmarkMetaDialog> createState() => _BookmarkMetaDialogState();
}

class _BookmarkMetaDialogState extends State<_BookmarkMetaDialog> {
  late final TextEditingController _folder;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _folder = TextEditingController(text: widget.folder);
    _note = TextEditingController(text: widget.note);
  }

  @override
  void dispose() {
    _folder.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.bookmarkEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _folder,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: loc.bookmarkFolder,
                hintText: loc.bookmarkFolderHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.bookmarkNote,
                hintText: loc.bookmarkNoteHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            (folder: _folder.text, note: _note.text),
          ),
          child: Text(loc.bookmarkMetaSave),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.entry});

  final BookmarkMetaEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.folder.isNotEmpty)
          Text(
            entry.folder,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (entry.note.isNotEmpty)
          Text(
            entry.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}
