import { describe, it, expect } from 'vitest';
import surahs from '../../src/data/surahs.json';

const load = (n: number) => import(`../../src/data/ayahs/${n}.json`).then((m) => m.default as {
  surah: number; ayahs: { n: number; juz: number; page: number; u: string; i: string; sajda: boolean }[];
});

describe('generated quran data', () => {
  it('has 114 surahs', () => expect(surahs.surahs).toHaveLength(114));
  it('totals 6236 ayahs', async () => {
    let total = 0;
    for (const s of surahs.surahs) total += (await load(s.id)).ayahs.length;
    expect(total).toBe(6236);
  });
  it('spot-checks: Fatiha 7 ayahs, Baqara 286, Kahf 110', () => {
    const byId = Object.fromEntries(surahs.surahs.map((s) => [s.id, s]));
    expect(byId[1].ayahCount).toBe(7);
    expect(byId[2].ayahCount).toBe(286);
    expect(byId[18].ayahCount).toBe(110);
  });
  it('spot-checks Ayat al-Kursi text (diacritic-tolerant)', async () => {
    const normalize = (s: string) =>
      s.replace(/[\u064B-\u0652\u0670\u0640]/g, '').replace(/[\u0671أإآ]/g, 'ا').replace(/ى/g, 'ي');
    const baqara = await load(2);
    const ayah = baqara.ayahs.find((a) => a.n === 255);
    expect(normalize(ayah?.i ?? '')).toContain('كرسي');
  });
});
