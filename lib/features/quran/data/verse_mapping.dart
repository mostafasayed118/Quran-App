import '../../../core/db/app_database.dart';
import '../domain/surah_summary.dart';
import '../domain/verse.dart';

/// Drift row → domain entity mapping (DIP pilot).
///
/// The frozen test doubles pin the repository signatures to drift rows, so
/// the data layer keeps returning them; the presentation boundary maps rows
/// to entities here instead.
extension AyahRowMapping on Ayah {
  Verse toVerse() => Verse(
        id: id,
        surahId: surahId,
        numberInSurah: numberInSurah,
        juz: juz,
        page: page,
        textUthmani: textUthmani,
        textImlaei: textImlaei,
        sajda: sajda,
      );
}

extension SurahRowMapping on Surah {
  SurahSummary toSummary() => SurahSummary(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        revelationType: revelationType,
        ayahCount: ayahCount,
        pagesStart: pagesStart,
        pagesEnd: pagesEnd,
      );
}
