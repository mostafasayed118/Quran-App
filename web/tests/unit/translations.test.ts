import { describe, it, expect } from 'vitest';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import surahs from '../../src/data/surahs.json';
import searchIndex from '../../src/data/search-index-en.json';

const dir = fileURLToPath(new URL('../../src/data/translation-en/', import.meta.url));

const load = (n: number) =>
  import(`../../src/data/translation-en/${n}.json`).then(
    (m) =>
      m.default as {
        surah: number;
        ayahs: { n: number; t: string }[];
      },
  );

describe('generated english translation', () => {
  it('has one file per surah (114)', () => {
    for (const s of surahs.surahs) {
      expect(existsSync(`${dir}${s.id}.json`), `missing ${s.id}.json`).toBe(true);
    }
  });
  it('matches surahs.json ayah counts and totals 6236', async () => {
    let total = 0;
    for (const s of surahs.surahs) {
      const data = await load(s.id);
      expect(data.surah).toBe(s.id);
      expect(data.ayahs.length, `surah ${s.id}`).toBe(s.ayahCount);
      total += data.ayahs.length;
    }
    expect(total).toBe(6236);
  });
  it('starts Fatiha with the Pickthall opening', async () => {
    const fatiha = await load(1);
    expect(fatiha.ayahs[0].t).toContain('In the name of Allah');
  });
});

describe('generated english search index', () => {
  it('stores one non-empty record per ayah (6236) in surah/ayah order', () => {
    expect(searchIndex.ayahs).toHaveLength(6236);
    let i = 0;
    for (const s of surahs.surahs) {
      for (let a = 1; a <= s.ayahCount; a++) {
        const r = searchIndex.ayahs[i++];
        expect(r.s, `record ${i}`).toBe(s.id);
        expect(r.a, `${s.id}:${a}`).toBe(a);
        expect(r.t.trim().length, `${s.id}:${a} empty`).toBeGreaterThan(0);
      }
    }
  });
});
