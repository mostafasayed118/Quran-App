import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/bookmark_meta.dart';
import '../../domain/verse.dart';
import 'bookmark_meta_cubit.dart';
import 'bookmark_meta_state.dart';
import 'bookmarks_cubit.dart';
import 'bookmarks_state.dart';

part 'bookmarks_folder_chips.dart';
part 'bookmarks_list.dart';
part 'bookmarks_meta.dart';

/// The bookmark list without its Scaffold, shared by the compact screen and
/// the workspace master pane.
class BookmarksBody extends StatelessWidget {
  /// Creates the body; [onSelect] replaces the route push in the workspace.
  const BookmarksBody({
    super.key,
    required this.onSelect,
    this.selectedAyahId,
    this.showMeta = false,
    this.onBrowseQuran,
  });

  /// Called with the tapped verse.
  final ValueChanged<Verse> onSelect;

  /// The highlighted verse, when a pane is open.
  final int? selectedAyahId;

  /// Whether the folder chips and the note/folder editor are rendered.
  final bool showMeta;

  /// The empty-state action; null hides it (the workspace is already in Quran).
  final VoidCallback? onBrowseQuran;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) => switch (state) {
        BookmarksLoading() => const LoadingView(),
        BookmarksFailed() => errorPane(
            loc,
            onRetry: context.read<BookmarksCubit>().reload,
          ),
        BookmarksReady() => state.entries.isEmpty
            ? EmptyState(
                loc.noBookmarks,
                actionLabel: onBrowseQuran == null ? null : loc.quran,
                onAction: onBrowseQuran,
              )
            : _body(context, state),
      },
    );
  }

  Widget _body(BuildContext context, BookmarksReady state) {
    if (!showMeta) {
      return _BookmarkList(
        state: state,
        meta: const <int, BookmarkMetaEntry>{},
        canEdit: false,
        onSelect: onSelect,
        selectedAyahId: selectedAyahId,
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
                onSelect: onSelect,
                selectedAyahId: selectedAyahId,
              ),
            ),
          ],
        );
      },
    );
  }
}
