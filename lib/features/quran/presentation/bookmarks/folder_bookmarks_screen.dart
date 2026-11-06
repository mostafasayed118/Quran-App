import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'folder_bookmarks_cubit.dart';
import 'folder_bookmarks_state.dart';

/// The bookmarks filed under one folder name.
class FolderBookmarksScreen extends StatelessWidget {
  /// Creates the screen; [folder] is the AppBar title.
  const FolderBookmarksScreen({super.key, required this.folder});

  /// The folder this screen shows.
  final String folder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<FolderBookmarksCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(folder)),
      body: AppContentFrame(
        child: BlocBuilder<FolderBookmarksCubit, FolderBookmarksState>(
          builder: (context, state) => switch (state) {
            FolderBookmarksLoading() => const LoadingView(),
            FolderBookmarksFailed() => errorPane(loc, onRetry: cubit.start),
            FolderBookmarksReady(:final items) when items.isEmpty =>
              EmptyState(loc.bookmarkFolderEmpty, icon: Icons.folder_open),
            FolderBookmarksReady(:final items) => ListView.builder(
                padding: EdgeInsets.only(bottom: appBottomInset(context)),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final verse = item.verse;
                  return ListTile(
                    leading: Text(
                      '${loc.number(verse.surahId)}:${loc.number(verse.numberInSurah)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textDirection: TextDirection.rtl,
                    ),
                    title: Text(
                      verse.textImlaei,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.note.isEmpty
                        ? null
                        : Text(
                            item.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => context.push(quranReaderPath(
                      surah: verse.surahId,
                      ayah: verse.numberInSurah,
                    )),
                  );
                },
              ),
          },
        ),
      ),
    );
  }
}
