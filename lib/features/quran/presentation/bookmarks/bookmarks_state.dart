import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/ayah_repository.dart';

part 'bookmarks_state.freezed.dart';

@freezed
sealed class BookmarksState with _$BookmarksState {
  const factory BookmarksState.loading() = BookmarksLoading;

  const factory BookmarksState.ready({required List<BookmarkEntry> entries}) =
      BookmarksReady;

  const factory BookmarksState.error({required String message}) = BookmarksError;
}
