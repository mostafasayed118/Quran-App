import { describe, it, expect } from 'vitest';
import { normalizeQuery, filterSurahs } from '../../src/lib/surah-filter';
import surahs from '../../src/data/surahs.json';

const list = surahs.surahs;

describe('normalizeQuery', () => {
  it('strips tashkeel and unifies hamza forms', () => {
    expect(normalizeQuery('الْكَهْف')).toBe('الكهف');
    expect(normalizeQuery('إسراء')).toBe('اسراء');
    expect(normalizeQuery('ٱلرَّحْمَٰنِ')).toBe('الرحمن');
  });
});

describe('filterSurahs', () => {
  it('empty query returns all', () => expect(filterSurahs(list, '')).toHaveLength(114));
  it('finds by number', () => expect(filterSurahs(list, '18')[0].id).toBe(18));
  it('finds by Arabic name with/without tashkeel', () => {
    expect(filterSurahs(list, 'الكهف')[0].id).toBe(18);
    expect(filterSurahs(list, 'الرحمن')[0].id).toBe(55);
  });
  it('finds by latin name', () => expect(filterSurahs(list, 'kahf')[0].id).toBe(18));
  it('exact name ranks before contains', () => {
    const ids = filterSurahs(list, 'النور').map((s) => s.id);
    expect(ids[0]).toBe(24);
  });
  it('finds by Arabic-Indic digits', () => expect(filterSurahs(list, '١٨')[0].id).toBe(18));
  it('finds decomposed-maddah surah name (ا + U+0653)', () => {
    expect(filterSurahs(list, '\u0627\u0653\u0644 \u0639\u0645\u0631\u0627\u0646')[0].id).toBe(3);
  });
  it('multi-match ranking guard for الـم', () => expect(filterSurahs(list, 'الم')[0].id).toBe(5));
});
