/// The domain projection of an ayah: what a feature outside the quran
/// feature needs in order to show an ayah.
///
/// The port ([AyahLookup]) is the seam; this is the vocabulary it speaks in
/// feature code. No drift row crosses the seam — the mapping happens inside
/// the port (see `ayah_lookup.dart`).
class AyahRef {
  /// Creates one ayah reference.
  const AyahRef({
    required this.id,
    required this.surahId,
    required this.numberInSurah,
    required this.textUthmani,
  });

  /// The ayah id (the global ayah number).
  final int id;

  /// The id of the surah the ayah belongs to.
  final int surahId;

  /// The ayah number inside its surah (1-based).
  final int numberInSurah;

  /// The Uthmani text of the ayah.
  final String textUthmani;
}

/// The domain projection of a surah: what a feature outside the quran
/// feature needs in order to name a surah.
class SurahRef {
  /// Creates one surah reference.
  const SurahRef({required this.id, required this.nameAr});

  /// The surah id (1-based).
  final int id;

  /// The Arabic name of the surah.
  final String nameAr;
}
