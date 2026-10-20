/// Normalizes Arabic text for local, diacritics-insensitive search.
///
/// Rules mirror the city-search convention (`features/prayer/data/
/// city_repository.dart`): strips diacritics (U+064B–U+065F), the
/// superscript alef (U+0670) and tatweel (U+0640), folds letter variants
/// (hamza-carrying alefs, alef maqsura, ta marbuta, hamza seats) to their
/// plain letters, then collapses whitespace and trims.
String normalizeArabic(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (_isArabicMark(rune)) continue;
    buffer.writeCharCode(_foldArabicLetter(rune));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Whether [text] matches [query] under [normalizeArabic], case-insensitive
/// for Latin text. An empty (or whitespace-only) query matches everything.
bool matchesQuery(String text, String query) {
  final normalizedQuery = normalizeArabic(query).toLowerCase();
  return normalizedQuery.isEmpty ||
      normalizeArabic(text).toLowerCase().contains(normalizedQuery);
}

bool _isArabicMark(int rune) =>
    (rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640;

int _foldArabicLetter(int rune) => switch (rune) {
      0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ -> ا
      0x0624 => 0x0648, // ؤ -> و
      0x0626 || 0x0649 => 0x064A, // ئ ى -> ي
      0x0629 => 0x0647, // ة -> ه
      _ => rune,
    };
