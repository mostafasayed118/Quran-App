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

/// One ayah as the reader renders it: display text with the trailing
/// verse-end marker already stripped ([displayUthmani]), plus the navigation
/// coordinates (surah, ayah number, juz, page).
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
    this.textUnicode,
    this.displayUthmani,
  });

  /// Same verse, with the Unicode Uthmani reading attached.
  Verse withUnicode(String? unicode) => Verse(
        id: id,
        surahId: surahId,
        numberInSurah: numberInSurah,
        juz: juz,
        page: page,
        textUthmani: textUthmani,
        textImlaei: textImlaei,
        sajda: sajda,
        textUnicode: unicode,
        displayUthmani: displayUthmani,
      );

  final int id;
  final int surahId;
  final int numberInSurah;
  final int juz;
  final int page;
  final String textUthmani;
  final String textImlaei;
  final bool sajda;

  /// The same verse in real Unicode Uthmani (OFL asset, one file per surah).
  ///
  /// Null only when the asset is missing for this surah; the reader then falls
  /// back to [textUthmani] (a private-use glyph encoding) and disables text
  /// selection for it, because copying those glyphs is meaningless elsewhere.
  final String? textUnicode;

  /// What belongs on the clipboard: Unicode Uthmani when available, otherwise
  /// the imlaei orthography. Never [textUthmani] — that is a glyph encoding.
  String get copyText => textUnicode ?? textImlaei;

  /// [textUthmani] with the ayah-end medallion already stripped.
  ///
  /// Computed once at the row→entity mapping boundary ([AyahRowMapping]).
  /// Null on a hand-built instance (tests, the clipboard path), in which case
  /// [displayText] strips on demand — never inside a hot rebuild.
  final String? displayUthmani;

  /// The text the reader draws for this verse.
  ///
  /// The reader rebuilds a card on every scroll tick; stripping the medallion
  /// allocates a rune list plus a fresh string for the whole ayah, so it runs
  /// once at mapping time rather than inside `build()`.
  String get displayText =>
      textUnicode ?? displayUthmani ?? stripAyahEndMarker(textUthmani);
}
