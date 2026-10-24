import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/wird_progress_sink.dart';

import '../../data/ayah_source.dart';
import '../../data/last_read_source.dart';
import '../../data/verse_mapping.dart';
import 'mushaf_page_block.dart';
import 'reader_state.dart';

/// The reader screen: one surah, in verses or in mushaf pages.
class ReaderCubit extends Cubit<ReaderState> {
  /// Creates the cubit for one surah and starts the load.
  ///
  /// [surahId] and [initialAyah] are the route parameters; the first load
  /// is fire-and-forget and ends in ready or failed. [wirdProgress] is
  /// optional — without it the reader just does not report wird progress.
  ReaderCubit({
    required AyahSource ayahRepository,
    required LastReadSource lastReadRepository,
    required int surahId,
    required int initialAyah,
    WirdProgressSink? wirdProgress,
  })  : _ayahRepository = ayahRepository,
        _lastReadRepository = lastReadRepository,
        _wirdProgress = wirdProgress,
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
  final WirdProgressSink? _wirdProgress;
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
        dev.log('surah $_surahId has no readable ayahs',
            name: 'quran_yahdi/reader');
        emit(ReaderState.failed(emptySurahId: _surahId));
        return;
      }
      if (isClosed) return;
      final startList =
          ayahs.where((a) => a.numberInSurah == _initialAyah).toList();
      unawaited(_saveLastRead(
        startList.isNotEmpty ? startList.first.id : ayahs.first.id,
      ));
      final verses = ayahs.map((a) => a.toVerse()).toList();
      emit(ReaderState.ready(
        surahId: _surahId,
        surahName: surah?.nameAr ?? '',
        initialAyah: _initialAyah,
        ayahs: verses,
        mushafPages: groupVersesByPage(verses),
        bookmarkedAyahIds: Set<int>.of(_bookmarkedIds),
        showBasmala: _surahId != 1 && _surahId != 9,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('reader load failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const ReaderState.failed());
    }
  }

  /// Persists the last-read marker; a storage failure is logged, never
  /// surfaced as an unhandled async error or a reader failure.
  Future<void> _saveLastRead(int ayahId) async {
    try {
      await _lastReadRepository.saveAyahId(ayahId);
    } on Object catch (error, stackTrace) {
      dev.log('last-read save failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
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

  /// Switches between the verses list and the mushaf pager.
  void toggleMode() {
    final current = state;
    if (current is! ReaderReady || isClosed) return;
    emit(current.copyWith(
      mode: current.mode == ReaderMode.verses
          ? ReaderMode.mushaf
          : ReaderMode.verses,
    ));
  }

  /// Toggles the bookmark of [ayahId]; the stream re-emits the new set.
  Future<void> toggleBookmark(int ayahId) async {
    try {
      await _ayahRepository.toggleBookmark(ayahId);
    } on Object catch (error, stackTrace) {
      dev.log('toggle bookmark failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// Records the mushaf page the user reached and advances the wird progress.
  ///
  /// [blockIndex] indexes the mushaf page blocks; an out-of-range index is
  /// ignored. The wird sink is optional and never fails the page change.
  Future<void> onMushafPageChanged(int blockIndex) async {
    final current = state;
    if (current is! ReaderReady) return;
    if (blockIndex < 0 || blockIndex >= current.mushafPages.length) return;
    final pageAyahs = current.mushafPages[blockIndex].ayahs;
    if (pageAyahs.isEmpty) return;
    await _saveLastRead(pageAyahs.first.id);
    final sink = _wirdProgress;
    if (sink == null) return;
    try {
      await sink.advanceTo(pageAyahs.first.id);
    } on Object catch (error, stackTrace) {
      dev.log('wird progress advance failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// Cancels the bookmark subscription before closing the cubit.
  @override
  Future<void> close() {
    _bookmarksSub?.cancel();
    return super.close();
  }
}
