import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/ayah_repository.dart';
import '../../data/ayah_source.dart';
import '../../data/verse_mapping.dart';
import 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._repo) : super(const BookmarksState.loading()) {
    _sub = _repo.watchBookmarkEntries().listen(
      (entries) {
        if (isClosed) return;
        emit(BookmarksState.ready(
          entries: entries.map((e) => e.ayah.toVerse()).toList(),
        ));
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(BookmarksState.error(message: error.toString()));
      },
    );
  }

  final AyahSource _repo;
  StreamSubscription<List<BookmarkEntry>>? _sub;

  Future<void> remove(int ayahId) => _repo.toggleBookmark(ayahId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
