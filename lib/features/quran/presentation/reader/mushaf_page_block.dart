import '../../domain/verse.dart';

export 'mushaf_page_block_rows.dart';

/// A single rendered page block in mushaf mode: the surah's ayahs that share
/// one mushaf page. Pages the surah owns no ayahs on are omitted (surah-
/// scoped mushaf, v1).
class MushafPageBlock {
  const MushafPageBlock({required this.page, required this.ayahs});

  final int page;
  final List<Verse> ayahs;
}

/// Groups domain ayahs into sorted page blocks (one block per mushaf page).
List<MushafPageBlock> groupVersesByPage(List<Verse> ayahs) {
  final byPage = <int, List<Verse>>{};
  for (final ayah in ayahs) {
    byPage.putIfAbsent(ayah.page, () => <Verse>[]).add(ayah);
  }
  final pages = byPage.keys.toList()..sort();
  return [
    for (final page in pages)
      MushafPageBlock(
        page: page,
        ayahs: (byPage[page]!
              ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah)))
            .toList(),
      ),
  ];
}
