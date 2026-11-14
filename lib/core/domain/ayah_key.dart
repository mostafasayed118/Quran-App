/// The global ayah key shared by the translation index and the reader.
///
/// The key is `surah * [stride] + ayah`. The stride is wider than the longest
/// surah (286 ayahs), so `~/` and `%` recover the pair without a map, and the
/// same integer works as a Drift/SQLite key and as a pack map key.
///
/// It is a storage/wire format, not a user-facing id: changing [stride] would
/// invalidate every installed translation index, so it is frozen. The helpers
/// are total and do no range validation — callers pass data that already came
/// from the Quran metadata, and a throwing decoder would change behavior at
/// the pack boundary.
abstract final class AyahKey {
  /// The distance between two surah blocks. 1000 > 286, so no collision.
  static const int stride = 1000;

  /// Encodes a surah/ayah pair.
  static int encode(int surah, int ayah) => surah * stride + ayah;

  /// The surah number of [key].
  static int surahOf(int key) => key ~/ stride;

  /// The ayah number of [key].
  static int ayahOf(int key) => key % stride;
}
