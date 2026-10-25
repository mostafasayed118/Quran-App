import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/verse.dart';

part 'bookmarks_state.freezed.dart';

@freezed
sealed class BookmarksState with _$BookmarksState {
  const factory BookmarksState.loading() = BookmarksLoading;

  const factory BookmarksState.ready({
    required List<Verse> entries,
    @Default(0) int lastBookmarkId,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool moreFailed,
  }) = BookmarksReady;

  const factory BookmarksState.failed() = BookmarksFailed;
}
