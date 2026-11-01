/// One row of the juz index, derived from the shipped ayah table.
class JuzSummary {
  /// Creates a juz start entry.
  const JuzSummary({
    required this.juz,
    required this.firstPage,
    required this.surahId,
    required this.numberInSurah,
    required this.surahName,
  });

  /// The juz number, 1..30.
  final int juz;

  /// The first mushaf page of the juz.
  final int firstPage;

  /// The surah that owns the first ayah of the juz.
  final int surahId;

  /// The ayah number inside [surahId] of the juz's first ayah.
  final int numberInSurah;

  /// The Arabic surah name for display.
  final String surahName;
}
