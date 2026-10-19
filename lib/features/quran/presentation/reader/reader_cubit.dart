import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/ayah_source.dart';
import '../../data/last_read_source.dart';
import '../../data/verse_mapping.dart';
import 'mushaf_page_block.dart';
import 'reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required AyahSource ayahRepository,
    required LastReadSource lastReadRepository,
    required int surahId,
    required int initialAyah,
  })  : _ayahRepository = ayahRepository,
        _lastReadRepository = lastReadRepository,
        _surahId = surahId,
        _initialAyah = initialAyah,
        super(ReaderState.loading(surahId: surahId, initialAyah: initialAyah)) {
    _bookmarksSub = ayahRepository.watchBookmarkedIds().listen(
          _onBookmarks,
          onError: (Object error, StackTrace stackTrace) => dev.log(
            'bookmarks stream error',
            name: 'quran_yahdi/reader',
            error: error,
            stackTrace: stackTrace,
          ),
        );
    _load();
  }

  final AyahSource _ayahRepository;
  final LastReadSource _lastReadRepository;
  final int _surahId;
  final int _initialAyah;
  StreamSubscription<Set<int>>? _bookmarksSub;
  final Set<int> _bookmarkedIds = <int>{};

  Future<void> _load() async {
    try {
      final (surah, ayahs) = await (
        _ayahRepository.surahById(_surahId),
        _ayahRepository.surahAyahs(_surahId),
      ).wait;
      if (ayahs.isEmpty) {
        if (isClosed) return;
        emit(ReaderState.error(
          message: 'surah $_surahId has no readable ayahs',
        ));
        return;
      }
      final startList =
          ayahs.where((a) => a.numberInSurah == _initialAyah).toList();
      unawaited(_lastReadRepository.saveAyahId(
        startList.isNotEmpty ? startList.first.id : ayahs.first.id,
      ));
      if (isClosed) return;
      emit(ReaderState.ready(
        surahId: _surahId,
        surahName: surah?.nameAr ?? '',
        initialAyah: _initialAyah,
        ayahs: ayahs.map((a) => a.toVerse()).toList(),
        mushafPages: groupAyahsByPage(ayahs),
        bookmarkedAyahIds: Set<int>.of(_bookmarkedIds),
        showBasmala: _surahId != 1 && _surahId != 9,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('reader load failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(ReaderState.error(message: error.toString()));
    }
  }

  /// Re-runs the load after a failure (error-state retry).
  Future<void> reload() {
    if (isClosed) return Future<void>.value();
    emit(ReaderState.loading(surahId: _surahId, initialAyah: _initialAyah));
    return _load();
  }

  void _onBookmarks(Set<int> ids) {
    _bookmarkedIds
      ..clear()
      ..addAll(ids);
    final current = state;
    if (current is ReaderReady && !isClosed) {
      emit(current.copyWith(bookmarkedAyahIds: Set<int>.of(_bookmarkedIds)));
    }
  }

  void toggleMode() {
    final current = state;
    if (current is! ReaderReady || isClosed) return;
    emit(current.copyWith(
      mode: current.mode == ReaderMode.verses
          ? ReaderMode.mushaf
          : ReaderMode.verses,
    ));
  }

  Future<void> toggleBookmark(int ayahId) async {
    await _ayahRepository.toggleBookmark(ayahId);
  }

  Future<void> onMushafPageChanged(int blockIndex) async {
    final current = state;
    if (current is! ReaderReady) return;
    if (blockIndex < 0 || blockIndex >= current.mushafPages.length) return;
    final pageAyahs = current.mushafPages[blockIndex].ayahs;
    if (pageAyahs.isEmpty) return;
    await _lastReadRepository.saveAyahId(pageAyahs.first.id);
  }

  @override
  Future<void> close() {
    _bookmarksSub?.cancel();
    return super.close();
  }
}
