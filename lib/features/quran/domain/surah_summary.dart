/// A surah's index-facing summary, decoupled from the drift row (DIP pilot).
///
/// Field names mirror the `Surah` row so the index screen's reads
/// (`nameAr`, `revelationType`, `ayahCount`, ...) keep compiling unchanged.
class SurahSummary {
  const SurahSummary({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.revelationType,
    required this.ayahCount,
    required this.pagesStart,
    required this.pagesEnd,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String revelationType;
  final int ayahCount;
  final int pagesStart;
  final int pagesEnd;

  /// Whether this surah was revealed in Makkah.
  ///
  /// [revelationType] is normalized to `makkah`/`madinah` at the mapping
  /// boundary, so an unknown DB value cannot reach the UI as a silent
  /// "Madinah" label.
  bool get isMakkah => revelationType == 'makkah';
}
