import { describe, it, expect } from 'vitest';
import { groupAyahsByPage } from '../../src/lib/mushaf';
import surahs from '../../src/data/surahs.json';

const load = (n: number) =>
  import(`../../src/data/ayahs/${n}.json`).then(
    (m) =>
      m.default as {
        surah: number;
        ayahs: { n: number; juz: number; page: number; u: string; i: string; sajda: boolean }[];
      },
  );

describe('mushaf page grouping', () => {
  it('groups surah ayahs into sorted page blocks (app-parity fixture)', () => {
    // Same fixture shape as the app's frozen test/mushaf_grouping_test.dart:
    // pages [2,2,3,4,4,4] → blocks [2,3,4] with counts [2,1,3].
    const fixture = [
      { n: 1, page: 2 },
      { n: 2, page: 2 },
      { n: 3, page: 3 },
      { n: 4, page: 4 },
      { n: 5, page: 4 },
      { n: 6, page: 4 },
    ];
    const blocks = groupAyahsByPage(fixture);
    expect(blocks.map((b) => b.page)).toEqual([2, 3, 4]);
    expect(blocks.map((b) => b.ayahs.length)).toEqual([2, 1, 3]);
    expect(blocks[0].ayahs.map((a) => a.n)).toEqual([1, 2]);
  });

  it('keeps every ayah page within its surah pagesStart..pagesEnd (all 114)', async () => {
    for (const s of surahs.surahs) {
      const data = await load(s.id);
      for (const a of data.ayahs) {
        expect(a.page, `surah ${s.id} ayah ${a.n} page ${a.page}`).toBeGreaterThanOrEqual(
          s.pagesStart,
        );
        expect(a.page, `surah ${s.id} ayah ${a.n} page ${a.page}`).toBeLessThanOrEqual(s.pagesEnd);
      }
    }
  });

  it("covers each surah's pages contiguously from pagesStart to pagesEnd (all 114)", async () => {
    for (const s of surahs.surahs) {
      const data = await load(s.id);
      const distinct = [...new Set(data.ayahs.map((a) => a.page))].sort((x, y) => x - y);
      expect(distinct[0], `surah ${s.id} first page`).toBe(s.pagesStart);
      expect(distinct[distinct.length - 1], `surah ${s.id} last page`).toBe(s.pagesEnd);
      expect(distinct.length, `surah ${s.id} page count`).toBe(s.pagesEnd - s.pagesStart + 1);
    }
  });

  it('spot pins: surah 1 → one block on page 1 (7 ayahs); surah 108 → one block on page 602 (3 ayahs)', async () => {
    const fatiha = groupAyahsByPage((await load(1)).ayahs);
    expect(fatiha).toHaveLength(1);
    expect(fatiha[0].page).toBe(1);
    expect(fatiha[0].ayahs).toHaveLength(7);

    const kawthar = groupAyahsByPage((await load(108)).ayahs);
    expect(kawthar).toHaveLength(1);
    expect(kawthar[0].page).toBe(602);
    expect(kawthar[0].ayahs).toHaveLength(3);
  });
});
