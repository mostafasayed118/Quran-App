/// The read seam the translation search needs: installed translation ids and
/// their full ayah indexes.
abstract interface class TranslationSearchSource {
  /// The ids of the installed translation packs, in install order.
  Future<List<String>> installedTranslationIds();

  /// The full `surah * 1000 + ayah` → text index of [packId]; empty when the
  /// pack is absent or unreadable.
  Future<Map<int, String>> translationIndex(String packId);
}
