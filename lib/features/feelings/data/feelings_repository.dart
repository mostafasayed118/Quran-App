import 'package:drift/drift.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../domain/feeling.dart';
import '../domain/saved_feeling_verse.dart';

/// A verse resolved from the catalog into the app's real Quran data.
class FeelingVerseView {
  const FeelingVerseView({
    required this.feeling,
    required this.verse,
    required this.fullText,
    required this.surahName,
    required this.juz,
    required this.ayahId,
    this.surahNameEn = '',
  });

  final FeelingKey feeling;
  final FeelingVerse verse;
  final String fullText;
  final String surahName;
  final int juz;
  final int ayahId;

  /// Raw English surah name from the catalog (`name_en`); the presentation
  /// layer picks it in English mode. Empty when the catalog row lacks it.
  final String surahNameEn;

  String get excerpt => verse.excerpt;
}

/// Reads feelings verses from the bundled Uthmani source and the local DB, and
/// owns the saved-verses table.
class FeelingsRepository {
  FeelingsRepository(this._db, this._uthmani, this._ayahs);

  final AppDatabase _db;
  final UthmaniTextSource _uthmani;
  final AyahRepository _ayahs;

  Future<FeelingVerseView> load(FeelingKey feeling, FeelingVerse verse) async {
    final texts = await _uthmani.forSurah(verse.surah);
    final surah = await _ayahs.surahById(verse.surah);
    final rows = await _ayahs.surahAyahs(verse.surah);
    final row = rows.firstWhere(
      (a) => a.numberInSurah == verse.ayah,
      orElse: () => throw StateError('ayah ${verse.reference} not in database'),
    );
    return FeelingVerseView(
      feeling: feeling,
      verse: verse,
      fullText: texts[verse.ayah] ?? '',
      surahName: surah?.nameAr ?? '',
      surahNameEn: surah?.nameEn ?? '',
      juz: row.juz,
      ayahId: row.id,
    );
  }

  Future<List<FeelingVerseView>> forFeeling(FeelingKey key) async {
    final feeling = FeelingsCatalog.byKey(key);
    if (feeling == null) return const <FeelingVerseView>[];
    final result = <FeelingVerseView>[];
    for (final verse in feeling.verses) {
      result.add(await load(key, verse));
    }
    return List.unmodifiable(result);
  }

  Stream<List<SavedFeelingVerse>> watchSaved() => _db
      .select(_db.feelingSavedVerses)
      .watch()
      .map(
        (rows) => [
          for (final row in rows)
            SavedFeelingVerse(
              id: row.id,
              ayahId: row.ayahId,
              feeling: FeelingKey.fromValue(row.feeling) ?? FeelingKey.qalaq,
              createdAt: row.createdAt,
            ),
        ]..sort((a, b) => b.id.compareTo(a.id)),
      );

  Future<int> savedCount() async {
    final rows = await _db.select(_db.feelingSavedVerses).get();
    return rows.length;
  }

  Future<bool> isSaved(int ayahId) async {
    final row = await (_db.select(
      _db.feelingSavedVerses,
    )..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull();
    return row != null;
  }

  Future<void> save(int ayahId, FeelingKey feeling) async {
    await _db
        .into(_db.feelingSavedVerses)
        .insert(
          FeelingSavedVersesCompanion.insert(
            ayahId: ayahId,
            feeling: feeling.value,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> unsave(int ayahId) async {
    await (_db.delete(
      _db.feelingSavedVerses,
    )..where((t) => t.ayahId.equals(ayahId))).go();
  }

  Future<void> delete(int id) async {
    await (_db.delete(
      _db.feelingSavedVerses,
    )..where((t) => t.id.equals(id))).go();
  }
}
