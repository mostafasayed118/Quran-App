import '../../../../core/db/app_database.dart';
import '../../data/verse_mapping.dart';
import '../../domain/verse.dart';

/// A single rendered page block in mushaf mode: the surah's ayahs that share
/// one mushaf page. Pages the surah owns no ayahs on are omitted (surah-
/// scoped mushaf, v1).
class MushafPageBlock {
  const MushafPageBlock({required this.page, required this.ayahs});

  final int page;
  final List<Verse> ayahs;
}

/// The parameter stays a list of drift rows: the frozen grouping test feeds
/// `repo.surahAyahs(...)` straight in; rows are mapped to entities here.
List<MushafPageBlock> groupAyahsByPage(List<Ayah> ayahs) {
  final byPage = <int, List<Ayah>>{};
  for (final ayah in ayahs) {
    byPage.putIfAbsent(ayah.page, () => <Ayah>[]).add(ayah);
  }
  final pages = byPage.keys.toList()..sort();
  return [
    for (final page in pages)
      MushafPageBlock(
        page: page,
        ayahs: (byPage[page]!
              ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah)))
            .map((a) => a.toVerse())
            .toList(),
      ),
  ];
}
