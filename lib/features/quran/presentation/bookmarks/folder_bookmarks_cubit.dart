import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../../core/domain/ayah_batch_lookup.dart';
import '../../../../core/domain/ayah_lookup.dart';
import '../../data/bookmark_meta.dart';
import '../../data/verse_mapping.dart';
import 'folder_bookmarks_state.dart';

/// The bookmarks that carry [folder], in surah/ayah order.
class FolderBookmarksCubit extends Cubit<FolderBookmarksState> {
  /// Creates the cubit for one folder.
  ///
  /// [batch] is optional on purpose: the frozen doubles implement `AyahLookup`
  /// only, and they keep the per-id path. Production passes the repository,
  /// which resolves the folder in one query.
  FolderBookmarksCubit({
    required String folder,
    required BookmarkMetaSource meta,
    required AyahLookup ayahs,
    AyahBatchLookup? batch,
  })  : _folder = folder,
        _meta = meta,
        _ayahs = ayahs,
        _batch = batch,
        super(const FolderBookmarksState.loading());

  final String _folder;
  final BookmarkMetaSource _meta;
  final AyahLookup _ayahs;
  final AyahBatchLookup? _batch;

  /// Loads the folder's ayah ids, resolves them and sorts by surah/ayah.
  Future<void> start() async {
    try {
      final meta = await _meta.load();
      final ids = [
        for (final entry in meta.entries)
          if (entry.value.folder == _folder) entry.key,
      ];
      final items = <FolderBookmark>[];
      final batch = _batch;
      if (batch != null) {
        // One query for the whole folder instead of one per bookmark.
        for (final ayah in await batch.ayahsByIds(ids)) {
          items.add(FolderBookmark(
            verse: ayah.toVerse(),
            note: meta[ayah.id]?.note ?? '',
          ));
        }
      } else {
        for (final id in ids) {
          final ayah = await _ayahs.ayahById(id);
          if (ayah == null) continue;
          items.add(FolderBookmark(
            verse: ayah.toVerse(),
            note: meta[id]?.note ?? '',
          ));
        }
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
      appLog('folder bookmarks load failed',
          name: 'quran_yahdi/bookmarks', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const FolderBookmarksState.failed());
    }
  }
}
