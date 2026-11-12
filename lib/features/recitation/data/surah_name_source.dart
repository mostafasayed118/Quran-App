/// Resolves surah numbers to their Arabic names for the player.
///
/// A narrow port rather than [ReciterInfoSource]: the player only needs the
/// names for the track title, and most test doubles of the reciter source do
/// not carry a surah catalog.
abstract interface class SurahNameSource {
  /// Arabic names of the given surahs, keyed by surah number.
  Future<Map<int, String>> surahNamesFor(List<int> surahIds);
}
