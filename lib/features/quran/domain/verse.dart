/// A single readable ayah, decoupled from the drift row (DIP pilot).
///
/// Field names mirror the `Ayah` row so presentation reads (`textImlaei`,
/// `numberInSurah`, ...) keep compiling unchanged.
/// Removes the ayah-end glyph `text_uthmani` carries as its last rune.
///
/// The HafsSmart-encoded column ends every ayah with one Private Use Area
/// glyph (U+E95A…U+E95F, the "smart" verse-end medallion). Its glyph advance
/// is narrower than its ink, so drawing it inside the verse text paints the
/// medallion on top of the last word. The reader draws the verse number
/// itself, so the marker is stripped before rendering.
///
/// The separator that carries the marker (a trailing space plus a RIGHT-TO-
/// LEFT MARK) is stripped with it, so the returned text ends on the ayah's
/// last letter — callers can then glue their own number with a no-break space.
///
/// Text without such a marker is returned unchanged.
String stripAyahEndMarker(String text) {
  final runes = text.trimRight().runes.toList();
  if (runes.isEmpty) return text;
  final last = runes.last;
  if (last < 0xE000 || last > 0xF8FF) return text;
  runes.removeLast();
  while (runes.isNotEmpty && _isMarkerSeparator(runes.last)) {
    runes.removeLast();
  }
  return String.fromCharCodes(runes);
}

bool _isMarkerSeparator(int rune) =>
    rune == 0x20 || rune == 0x200E || rune == 0x200F;

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
