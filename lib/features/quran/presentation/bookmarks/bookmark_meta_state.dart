import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/bookmark_meta.dart';

part 'bookmark_meta_state.freezed.dart';

@freezed
sealed class BookmarkMetaState with _$BookmarkMetaState {
  const factory BookmarkMetaState.loading() = BookmarkMetaLoading;

  const factory BookmarkMetaState.failed() = BookmarkMetaFailed;

  const factory BookmarkMetaState.ready({
    @Default(<int, BookmarkMetaEntry>{}) Map<int, BookmarkMetaEntry> entries,
  }) = BookmarkMetaReady;
}

/// The distinct folder names in the store, sorted.
extension BookmarkMetaFolders on BookmarkMetaReady {
  /// Every non-empty folder name once.
  List<String> get folders {
    final names = <String>{
      for (final entry in entries.values)
        if (entry.folder.isNotEmpty) entry.folder,
    };
    final list = names.toList()..sort();
    return list;
  }
}
