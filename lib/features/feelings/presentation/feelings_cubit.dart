import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/ayah_batch_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_ref.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/feelings_repository.dart';
import '../domain/feeling.dart';
import '../domain/saved_feeling_verse.dart';
import 'feelings_state.dart';

/// Q43: catalog, hero and the live saved count.
class FeelingsCubit extends Cubit<FeelingsState> {
  FeelingsCubit(this._repo) : super(const FeelingsState.loading());

  final FeelingsRepository _repo;

  Future<void> start() async {
    try {
      final count = await _repo.savedCount();
      emit(
        FeelingsState.ready(
          feelings: FeelingsCatalog.ordered,
          heroExcerpt: FeelingsCatalog.heroExcerpt,
          savedCount: count,
        ),
      );
    } on Object catch (error, stackTrace) {
      appLog(
        'feelings load failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const FeelingsState.failed());
    }
  }
}

/// Q44: the two verses of one feeling.
class FeelingVersesCubit extends Cubit<FeelingVersesState> {
  FeelingVersesCubit(this._repo, this._feeling)
    : super(const FeelingVersesState.loading());

  final FeelingsRepository _repo;
  final FeelingKey _feeling;

  Future<void> start() async {
    try {
      final verses = await _repo.forFeeling(_feeling);
      emit(FeelingVersesState.ready(feeling: _feeling, verses: verses));
    } on Object catch (error, stackTrace) {
      appLog(
        'feeling verses load failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const FeelingVersesState.failed());
    }
  }
}

/// Q45: one verse, its save state and actions.
class VerseDetailCubit extends Cubit<VerseDetailState> {
  VerseDetailCubit(
    this._repo,
    this._feeling,
    this._surah,
    this._ayah, {
    Future<void> Function(int surah, String surahName)? playSurah,
  }) : _playSurah = playSurah,
       super(const VerseDetailState.loading());

  final FeelingsRepository _repo;
  final FeelingKey _feeling;
  final int _surah;
  final int _ayah;
  final Future<void> Function(int surah, String surahName)? _playSurah;

  FeelingVerseView? _verse;

  /// Plays the verse's whole surah through the app's existing player.
  Future<void> listen() async {
    final verse = _verse;
    if (verse == null || _playSurah == null) return;
    await _playSurah(verse.verse.surah, verse.surahName);
  }

  Future<void> start() async {
    try {
      final feeling = FeelingsCatalog.byKey(_feeling);
      if (feeling == null) {
        emit(const VerseDetailState.failed());
        return;
      }
      final index = feeling.verses.indexWhere(
        (v) => v.surah == _surah && v.ayah == _ayah,
      );
      if (index < 0) {
        emit(const VerseDetailState.failed());
        return;
      }
      final verse = await _repo.load(_feeling, feeling.verses[index]);
      _verse = verse;
      final saved = await _repo.isSaved(verse.ayahId);
      emit(VerseDetailState.ready(verse: verse, isSaved: saved));
    } on Object catch (error, stackTrace) {
      appLog(
        'verse detail load failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const VerseDetailState.failed());
    }
  }

  Future<void> toggleSave() async {
    final verse = _verse;
    final current = state;
    if (verse == null || current is! VerseDetailReady) return;
    try {
      if (current.isSaved) {
        await _repo.unsave(verse.ayahId);
        emit(VerseDetailState.ready(verse: verse, isSaved: false));
      } else {
        await _repo.save(verse.ayahId, _feeling);
        emit(VerseDetailState.ready(verse: verse, isSaved: true));
      }
    } on Object catch (error, stackTrace) {
      appLog(
        'verse save failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Q46: the saved list.
class SavedVersesCubit extends Cubit<SavedVersesState> {
  SavedVersesCubit(this._repo, {AyahLookup? lookup, AyahBatchLookup? batch})
    : _lookup = lookup,
      _batch = batch,
      super(const SavedVersesState.loading()) {
    _sub = _repo.watchSaved().listen(
      _onSaved,
      onError: (Object error, StackTrace stack) {
        appLog(
          'saved verses watch failed',
          name: 'quran_yahdi/feelings',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  final FeelingsRepository _repo;
  final AyahLookup? _lookup;
  final AyahBatchLookup? _batch;
  StreamSubscription<List<SavedFeelingVerse>>? _sub;

  /// Resolves the whole saved list in one batch read, then emits the labels
  /// with it. A rebuild no longer re-queries one ayah per visible row.
  ///
  /// [batch] is optional for the frozen doubles that only implement
  /// `AyahLookup`; that path stays per-id but lives here, never in the widget.
  Future<void> _onSaved(List<SavedFeelingVerse> verses) async {
    final refs = <int, AyahRef>{};
    try {
      final batch = _batch;
      if (batch != null) {
        final ids = [for (final verse in verses) verse.ayahId];
        if (ids.isNotEmpty) {
          for (final ayah in await batch.ayahsByIds(ids)) {
            refs[ayah.id] = AyahRef(
              surahId: ayah.surahId,
              numberInSurah: ayah.numberInSurah,
              textUthmani: ayah.textUthmani,
            );
          }
        }
      } else {
        final lookup = _lookup;
        if (lookup != null) {
          for (final verse in verses) {
            final ref = await lookup.ayahRefById(verse.ayahId);
            if (ref != null) refs[verse.ayahId] = ref;
          }
        }
      }
    } on Object catch (error, stackTrace) {
      appLog(
        'saved verse refs resolve failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (isClosed) return;
    emit(SavedVersesState.ready(verses: verses, refs: Map.unmodifiable(refs)));
  }

  Future<void> delete(int id) => _repo.delete(id);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
