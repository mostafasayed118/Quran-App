import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/feelings_repository.dart';
import '../domain/feeling.dart';
import 'feelings_state.dart';

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
