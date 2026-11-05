import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/bookmark_meta.dart';
import '../../data/bookmark_meta_repository.dart';
import 'bookmark_meta_state.dart';

/// The bookmark folders and notes: load, edit and clear one bookmark at a time.
///
/// Every mutation is optimistic and reverts to the previous map when the
/// write fails, so a note never appears saved when it is not.
class BookmarkMetaCubit extends Cubit<BookmarkMetaState> {
  /// Creates the cubit over [source].
  BookmarkMetaCubit({required BookmarkMetaSource source})
      : _source = source,
        super(const BookmarkMetaState.loading());

  final BookmarkMetaSource _source;

  /// Loads the persisted metadata.
  Future<void> start() async {
    try {
      final entries = await _source.load();
      if (!isClosed) emit(BookmarkMetaState.ready(entries: entries));
    } on Object catch (error, stackTrace) {
      dev.log('bookmark metadata load failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const BookmarkMetaState.failed());
    }
  }

  /// The metadata for [ayahId], or null when it has no folder and no note.
  BookmarkMetaEntry? entryFor(int ayahId) {
    final current = state;
    return current is BookmarkMetaReady ? current.entries[ayahId] : null;
  }

  /// Stores the trimmed folder/note pair for [ayahId].
  ///
  /// A pair where both are empty removes the entry. Returns whether the write
  /// landed (a no-op change counts as success).
  Future<bool> set(
    int ayahId, {
    required String folder,
    required String note,
  }) {
    final current = state;
    if (current is! BookmarkMetaReady) return Future<bool>.value(false);
    final next = Map<int, BookmarkMetaEntry>.of(current.entries);
    final entry = BookmarkMetaEntry(folder: folder, note: note).normalized();
    if (entry.isEmpty) {
      next.remove(ayahId);
    } else {
      next[ayahId] = entry;
    }
    return _persist(current, next);
  }

  /// Removes the metadata of [ayahId].
  Future<bool> remove(int ayahId) {
    final current = state;
    if (current is! BookmarkMetaReady) return Future<bool>.value(false);
    if (!current.entries.containsKey(ayahId)) return Future<bool>.value(true);
    final next = Map<int, BookmarkMetaEntry>.of(current.entries)
      ..remove(ayahId);
    return _persist(current, next);
  }

  Future<bool> _persist(
    BookmarkMetaReady previous,
    Map<int, BookmarkMetaEntry> next,
  ) async {
    final normalized = BookmarkMetaRepository.normalize(next);
    if (_sameMap(normalized, previous.entries)) return true;
    emit(BookmarkMetaState.ready(entries: normalized));
    try {
      await _source.save(normalized);
      return true;
    } on Object catch (error, stackTrace) {
      dev.log('bookmark metadata save failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(previous);
      return false;
    }
  }

  static bool _sameMap(
    Map<int, BookmarkMetaEntry> a,
    Map<int, BookmarkMetaEntry> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
