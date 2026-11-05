import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/ayah_lookup.dart';
import '../../data/bookmark_meta.dart';
import '../../data/verse_mapping.dart';
import 'folder_bookmarks_state.dart';

/// The bookmarks that carry [folder], in surah/ayah order.
class FolderBookmarksCubit extends Cubit<FolderBookmarksState> {
  /// Creates the cubit for one folder.
  FolderBookmarksCubit({
    required String folder,
    required BookmarkMetaSource meta,
    required AyahLookup ayahs,
  })  : _folder = folder,
        _meta = meta,
        _ayahs = ayahs,
        super(const FolderBookmarksState.loading());

  final String _folder;
  final BookmarkMetaSource _meta;
  final AyahLookup _ayahs;

  /// Loads the folder's ayah ids, resolves them and sorts by surah/ayah.
  Future<void> start() async {
    try {
      final meta = await _meta.load();
      final ids = [
        for (final entry in meta.entries)
          if (entry.value.folder == _folder) entry.key,
      ];
      final items = <FolderBookmark>[];
      for (final id in ids) {
        final ayah = await _ayahs.ayahById(id);
        if (ayah == null) continue;
        items.add(FolderBookmark(
          verse: ayah.toVerse(),
          note: meta[id]?.note ?? '',
        ));
      }
      items.sort((a, b) {
        final bySurah = a.verse.surahId.compareTo(b.verse.surahId);
        return bySurah != 0
            ? bySurah
            : a.verse.numberInSurah.compareTo(b.verse.numberInSurah);
      });
      if (isClosed) return;
      emit(FolderBookmarksState.ready(
        folder: _folder,
        items: List<FolderBookmark>.unmodifiable(items),
      ));
    } on Object catch (error, stackTrace) {
      dev.log('folder bookmarks load failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const FolderBookmarksState.failed());
    }
  }
}
