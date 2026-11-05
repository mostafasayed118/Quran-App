import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/verse.dart';

part 'folder_bookmarks_state.freezed.dart';

/// One bookmarked ayah inside a folder.
class FolderBookmark {
  /// Creates an item.
  const FolderBookmark({required this.verse, required this.note});

  /// The bookmarked ayah.
  final Verse verse;

  /// The user's note; empty when none.
  final String note;
}

@freezed
sealed class FolderBookmarksState with _$FolderBookmarksState {
  const factory FolderBookmarksState.loading() = FolderBookmarksLoading;

  const factory FolderBookmarksState.failed() = FolderBookmarksFailed;

  const factory FolderBookmarksState.ready({
    required String folder,
    @Default(<FolderBookmark>[]) List<FolderBookmark> items,
  }) = FolderBookmarksReady;
}
