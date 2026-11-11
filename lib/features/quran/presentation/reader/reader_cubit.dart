import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/wird_progress_sink.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../data/ayah_source.dart';
import '../../data/last_read_source.dart';
import '../../data/page_anchor_source.dart';
import '../../data/reader_layout_source.dart';
import '../../data/reader_settings_source.dart';
import '../../data/uthmani_text_source.dart';
import '../../data/verse_mapping.dart';
import 'reader_state.dart';

/// Al-Fatiha carries the basmala as its first ayah; At-Tawbah has none.
const Set<int> _basmalaExemptSurahIds = {1, 9};

/// The reader screen: one surah, in verses or in mushaf pages.
class ReaderCubit extends Cubit<ReaderState> {
  /// Creates the cubit for one surah; the constructor is side-effect free
  /// and does no work — [start] performs the first load.
  ///
  /// [surahId] and [initialAyah] are the route parameters; the first load
  /// ends in ready or failed. [wirdProgress] is optional — without it the
  /// reader just does not report wird progress.
  ReaderCubit({
    required AyahSource ayahRepository,
    required LastReadSource lastReadRepository,
    required int surahId,
    required int initialAyah,
    WirdProgressSink? wirdProgress,
    UthmaniTextSource? uthmani,
    PageAnchorSource? pageAnchors,
    ReaderSettingsSource? settings,
    ReaderLayoutSource? layout,
  })  : _ayahRepository = ayahRepository,
        _lastReadRepository = lastReadRepository,
        _wirdProgress = wirdProgress,
        _uthmani = uthmani,
        _pageAnchors = pageAnchors,
        _settings = settings,
        _layout = layout,
        _surahId = surahId,
        _initialAyah = initialAyah,
        super(ReaderState.loading(surahId: surahId, initialAyah: initialAyah));

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() async {
    if (_bookmarksSub != null) return;
    _bookmarksSub = _ayahRepository.watchBookmarkedIds().listen(
          _onBookmarks,
          onError: (Object error, StackTrace stackTrace) => appLog(
            'bookmarks stream error',
            name: 'quran_yahdi/reader',
            error: error,
            stackTrace: stackTrace,
          ),
        );
    await _load();
  }

  final AyahSource _ayahRepository;
  final LastReadSource _lastReadRepository;
  final WirdProgressSink? _wirdProgress;
  final UthmaniTextSource? _uthmani;
  final PageAnchorSource? _pageAnchors;
  final ReaderSettingsSource? _settings;
  final ReaderLayoutSource? _layout;
  final int _surahId;
  final int _initialAyah;
  StreamSubscription<Set<int>>? _bookmarksSub;
  final Set<int> _bookmarkedIds = <int>{};
  int? _lastVisibleAyahId;

  /// The live reading anchor. Kept off the state so scrolling does not emit;
  /// [toggleMode] copies it into the ready state for the next mode's first
  /// frame.
  int _currentAyahId = 0;

  Future<void> _load() async {
    try {
      final (surah, ayahs) = await (
        _ayahRepository.surahById(_surahId),
        _ayahRepository.surahAyahs(_surahId),
      ).wait;
      if (ayahs.isEmpty) {
        if (isClosed) return;
        appLog('surah $_surahId has no readable ayahs',
            name: 'quran_yahdi/reader');
        emit(ReaderState.failed(emptySurahId: _surahId));
        return;
      }
      if (isClosed) return;
      // 0 (and any negative the route clamped) is the "no specific ayah"
      // sentinel and stays 0. A positive ayah outside the surah is a bad deep
      // link: render the first ayah and report that instead.
      final requested = _initialAyah;
      final match = requested > 0
          ? ayahs.where((a) => a.numberInSurah == requested).firstOrNull
          : null;
      final startAyah = match ?? ayahs.first;
      final startAyahId = startAyah.id;
      _lastVisibleAyahId = startAyahId;
      _currentAyahId = startAyahId;
      await _saveStartIfNeeded(startAyahId);
      // Unicode Uthmani is an asset (no DB migration). When it is missing the
      // verses keep glyph text and the reader turns selection off.
      final unicode =
          await _uthmani?.forSurah(_surahId) ?? const <int, String>{};
      final (fontScale, lineHeight) =
          await (_loadFontScale(), _loadLineHeight()).wait;
      if (isClosed) return;
      final verses = ayahs
          .map((a) => a.toVerse().withUnicode(unicode[a.numberInSurah]))
          .toList();
      emit(ReaderState.ready(
        surahId: _surahId,
        surahName: surah?.nameAr ?? '',
        initialAyah: requested > 0 ? startAyah.numberInSurah : 0,
        currentAyahId: startAyahId,
        ayahs: verses,
        bookmarkedAyahIds: Set<int>.of(_bookmarkedIds),
        showBasmala: !_basmalaExemptSurahIds.contains(_surahId),
        fontScale: fontScale,
        lineHeight: lineHeight,
      ));
    } on Object catch (error, stackTrace) {
      appLog('reader load failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const ReaderState.failed());
    }
  }

  /// Seeds the marker on a first read or an explicit deep link, but never
  /// rewinds an existing continue-reading position just because the user
  /// opened the surah at verse 1.
  Future<void> _saveStartIfNeeded(int startAyahId) async {
    try {
      final existing = await _lastReadRepository.loadAyahId();
      if (_initialAyah > 0 || existing == null || existing <= 0) {
        await _saveLastRead(startAyahId);
      }
    } on Object catch (error, stackTrace) {
      appLog('last-read read failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// Persists the last-read marker; a storage failure is logged, never
  /// surfaced as an unhandled async error or a reader failure.
  Future<void> _saveLastRead(int ayahId) async {
    try {
      await _lastReadRepository.saveAyahId(ayahId);
    } on Object catch (error, stackTrace) {
      appLog('last-read save failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// Records the first verse currently visible in the verse list.
  ///
  /// The verse list reports the leading visible index; duplicate reports for
  /// the same ayah are dropped, so scrolling within one card does not write
  /// the database on every frame.
  Future<void> onVisibleAyah(int ayahId) async {
    if (ayahId <= 0 || ayahId == _lastVisibleAyahId) return;
    _lastVisibleAyahId = ayahId;
    _currentAyahId = ayahId;
    await _saveLastRead(ayahId);
    // Verse mode feeds the same wird plan as mushaf paging: scrolling past a
    // verse advances the read-up-to pointer (max-wins on the sink side).
    final sink = _wirdProgress;
    if (sink == null) return;
    try {
      await sink.advanceTo(ayahId);
    } on Object catch (error, stackTrace) {
      appLog('wird progress advance failed',
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
      currentAyahId:
          _currentAyahId > 0 ? _currentAyahId : current.currentAyahId,
      mode: current.mode == ReaderMode.verses
          ? ReaderMode.mushaf
          : ReaderMode.verses,
    ));
  }

  Future<double> _loadFontScale() async {
    try {
      return await _settings?.loadFontScale() ?? 1.0;
    } on Object catch (error, stackTrace) {
      appLog('reader font scale read failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      return 1.0;
    }
  }

  /// Sets the reader font scale (0.8–2.0); a failed write keeps the on-screen
  /// value and only logs.
  Future<void> setFontScale(double scale) async {
    final current = state;
    if (current is! ReaderReady || isClosed) return;
    final safe = scale < 0.8 ? 0.8 : (scale > 2.0 ? 2.0 : scale);
    if (safe == current.fontScale) return;
    emit(current.copyWith(fontScale: safe));
    try {
      await _settings?.saveFontScale(safe);
    } on Object catch (error, stackTrace) {
      appLog('reader font scale write failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  Future<double> _loadLineHeight() async {
    try {
      return await _layout?.loadLineHeight() ??
          ReaderLayoutSource.defaultLineHeight;
    } on Object catch (error, stackTrace) {
      appLog('reader line height read failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      return ReaderLayoutSource.defaultLineHeight;
    }
  }

  /// Sets the reader line height (1.6–3.0); a failed write keeps the
  /// on-screen value and only logs.
  Future<void> setLineHeight(double lineHeight) async {
    final current = state;
    if (current is! ReaderReady || isClosed) return;
    final safe = lineHeight < ReaderLayoutSource.minLineHeight
        ? ReaderLayoutSource.minLineHeight
        : (lineHeight > ReaderLayoutSource.maxLineHeight
            ? ReaderLayoutSource.maxLineHeight
            : lineHeight);
    if (safe == current.lineHeight) return;
    emit(current.copyWith(lineHeight: safe));
    try {
      await _layout?.saveLineHeight(safe);
    } on Object catch (error, stackTrace) {
      appLog('reader line height write failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// The surah + ayah of [page]'s first row; null without a source or on a
  /// failed read.
  Future<({int surahId, int numberInSurah})?> anchorForPage(int page) async {
    final source = _pageAnchors;
    if (source == null) return null;
    try {
      return await source.anchorForPage(page);
    } on Object catch (error, stackTrace) {
      appLog('page anchor read failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// Toggles the bookmark of [ayahId]; the stream re-emits the new set.
  ///
  /// Returns whether the write landed, so the reader can confirm the change or
  /// report the failure instead of leaving a star that silently did nothing.
  Future<bool> toggleBookmark(int ayahId) async {
    try {
      await _ayahRepository.toggleBookmark(ayahId);
      return true;
    } on Object catch (error, stackTrace) {
      appLog('toggle bookmark failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
      return false;
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
    _currentAyahId = pageAyahs.first.id;
    await _saveLastRead(pageAyahs.first.id);
    final sink = _wirdProgress;
    if (sink == null) return;
    try {
      await sink.advanceTo(pageAyahs.first.id);
    } on Object catch (error, stackTrace) {
      appLog('wird progress advance failed',
          name: 'quran_yahdi/reader', error: error, stackTrace: stackTrace);
    }
  }

  /// Cancels the bookmark subscription before closing the cubit.
  @override
  Future<void> close() async {
    await _bookmarksSub?.cancel();
    return super.close();
  }
}
