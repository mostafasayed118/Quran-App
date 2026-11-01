/// Resolves a mushaf page to the first ayah on it.
///
/// A page can span surahs, so the reader route still needs a surah + ayah; the
/// reader opens the page that contains that ayah.
abstract interface class PageAnchorSource {
  /// The surah and ayah of the first row on [page], or null when out of range.
  Future<({int surahId, int numberInSurah})?> anchorForPage(int page);
}
