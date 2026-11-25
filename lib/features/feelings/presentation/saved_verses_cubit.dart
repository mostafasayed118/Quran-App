import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/ayah_batch_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_ref.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/feelings_repository.dart';
import '../domain/saved_feeling_verse.dart';
import 'feelings_state.dart';

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
