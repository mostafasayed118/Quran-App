import 'dart:developer' as dev;

import '../../../core/db/app_database.dart';
import '../domain/surah_summary.dart';
import '../domain/verse.dart';

/// Drift row → domain entity mapping (DIP pilot).
///
/// The frozen test doubles pin the repository signatures to drift rows, so
/// the data layer keeps returning them; the presentation boundary maps rows
/// to entities here instead.
extension AyahRowMapping on Ayah {
  /// Maps this row to the reader-facing [Verse] model.
  ///
  /// The ayah-end medallion is stripped here, once per row, so the reader
  /// never does it inside a rebuild.
  Verse toVerse() => Verse(
        id: id,
        surahId: surahId,
        numberInSurah: numberInSurah,
        juz: juz,
        page: page,
        textUthmani: textUthmani,
        textImlaei: textImlaei,
        sajda: sajda,
        displayUthmani: stripAyahEndMarker(textUthmani),
      );
}

extension SurahRowMapping on Surah {
  /// Maps this row to the list-facing [SurahSummary] model.
  SurahSummary toSummary() => SurahSummary(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        revelationType: _normalizeRevelationType(revelationType),
        ayahCount: ayahCount,
        pagesStart: pagesStart,
        pagesEnd: pagesEnd,
      );
}

/// Normalizes the free-text DB column to the two values the UI understands.
///
/// An unknown value is LOGGED and falls back to `madinah` so the screen stays
/// usable; the log names the bad row, but the UI still shows the fallback.
String _normalizeRevelationType(String raw) {
  final value = raw.toLowerCase().trim();
  if (value == 'makkah' || value == 'madinah') return value;
  dev.log(
    'unknown revelation type',
    name: 'quran_yahdi/quran',
    error: raw,
  );
  return 'madinah';
}
