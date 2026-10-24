import '../db/app_database.dart';
import 'ayah_ref.dart';

/// Cross-feature seam for the quran feature's ayah/surah lookups.
///
/// The drift rows live in core/db, so the port stays row-typed without
/// dragging the quran feature's data layer into other features.
///
/// The three row-typed members below are LEGACY: the frozen test doubles
/// implement them, so their signatures are pinned. Feature code must use the
/// domain-typed accessors of [AyahLookupRefs] instead — they return
/// [AyahRef]/[SurahRef], so no drift row reaches a cubit.
abstract interface class AyahLookup {
  /// The ayah with [ayahId]; null when the id is unknown.
  ///
  /// Legacy row-typed member (frozen doubles) — prefer
  /// [AyahLookupRefs.ayahRefById].
  Future<Ayah?> ayahById(int ayahId);

  /// The surah with [surahId]; null when the id is unknown.
  ///
  /// Legacy row-typed member (frozen doubles) — prefer
  /// [AyahLookupRefs.surahRefById].
  Future<Surah?> surahById(int surahId);

  /// The ayahs of [surahId] between [fromAyah] and [toAyah] inclusive, in
  /// ayah order; empty when the range holds no ayah.
  ///
  /// Legacy row-typed member (frozen doubles) — prefer
  /// [AyahLookupRefs.ayahRefsForRange].
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah);
}

/// The domain-typed view of [AyahLookup]: the same reads, mapped to
/// [AyahRef]/[SurahRef] at the seam so no drift row reaches a cubit.
extension AyahLookupRefs on AyahLookup {
  /// The ayah with [ayahId] as a domain reference; null when unknown.
  Future<AyahRef?> ayahRefById(int ayahId) async {
    final row = await ayahById(ayahId);
    if (row == null) return null;
    return AyahRef(
      surahId: row.surahId,
      numberInSurah: row.numberInSurah,
      textUthmani: row.textUthmani,
    );
  }

  /// The surah with [surahId] as a domain reference; null when unknown.
  Future<SurahRef?> surahRefById(int surahId) async {
    final row = await surahById(surahId);
    if (row == null) return null;
    return SurahRef(nameAr: row.nameAr);
  }

  /// The ayahs of [surahId] between [fromAyah] and [toAyah] inclusive, in
  /// ayah order; empty when the range holds no ayah.
  Future<List<AyahRef>> ayahRefsForRange(
    int surahId,
    int fromAyah,
    int toAyah,
  ) async {
    final rows = await ayahsForRange(surahId, fromAyah, toAyah);
    return [
      for (final row in rows)
        AyahRef(
          surahId: row.surahId,
          numberInSurah: row.numberInSurah,
          textUthmani: row.textUthmani,
        ),
    ];
  }
}
