/// A single readable ayah, decoupled from the drift row (DIP pilot).
///
/// Field names mirror the `Ayah` row so presentation reads (`textImlaei`,
/// `numberInSurah`, ...) keep compiling unchanged.
class Verse {
  const Verse({
    required this.id,
    required this.surahId,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    required this.textUthmani,
    required this.textImlaei,
    required this.sajda,
  });

  final int id;
  final int surahId;
  final int numberInSurah;
  final int juz;
  final int page;
  final String textUthmani;
  final String textImlaei;
  final bool sajda;
}
