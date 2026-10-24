import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/ayah_repository.dart';
import '../../data/ayah_source.dart';
import '../../data/verse_mapping.dart';
import 'bookmarks_state.dart';

/// The bookmarks screen: the live list of the user's bookmarked ayahs.
class BookmarksCubit extends Cubit<BookmarksState> {
  /// Creates the cubit and subscribes to the bookmark stream.
  ///
  /// The subscription is the source of truth: every change to the
  /// bookmarks re-emits the ready state.
  BookmarksCubit(this._repo) : super(const BookmarksState.loading()) {
    _sub = _repo.watchBookmarkEntries().listen(
      (entries) {
        if (isClosed) return;
        emit(BookmarksState.ready(
          entries: entries.map((e) => e.ayah.toVerse()).toList(),
        ));
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('bookmarks stream failed',
            name: 'quran_yahdi/bookmarks',
            error: error,
            stackTrace: stackTrace);
        if (isClosed) return;
        emit(const BookmarksState.failed());
      },
    );
  }

  final AyahSource _repo;
  StreamSubscription<List<BookmarkEntry>>? _sub;

  /// Removes the bookmark of [ayahId]; a row that is already unbookmarked
  /// stays removed (the reader star keeps the toggle).
  Future<void> remove(int ayahId) => _repo.deleteBookmark(ayahId);

  /// Cancels the bookmark subscription before closing the cubit.
  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
