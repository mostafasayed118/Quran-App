import { describe, it, expect } from 'vitest';
import { loadSearchIndex, matchSpan, searchAyahs } from '../../src/lib/search';

const ids = (hits: { s: number; a: number }[]) => hits.map((h) => `${h.s}:${h.a}`);

const BASMALA_EN = 'In the Name of Allah, the Most Gracious, the Most Merciful';

describe('english search index', () => {
  it('loads 6,236 english records once per locale', async () => {
    const records = await loadSearchIndex('en');
    expect(records).toHaveLength(6236);
    expect(await loadSearchIndex('en')).toBe(records); // module-level cache
  });

  it('finds 1:1 for "Most Merciful" with the english verse text', () => {
    const hits = searchAyahs('Most Merciful', 5, 'en');
    expect(ids(hits)).toContain('1:1');
    expect(hits[0]).toEqual({ s: 1, a: 1, text: BASMALA_EN });
    expect(hits.length).toBeLessThanOrEqual(5);
  });

  it('matches case-insensitively and maps the mark span back to the raw text', () => {
    expect(searchAyahs('most merciful', 5, 'en')).toEqual(searchAyahs('Most Merciful', 5, 'en'));
    const span = matchSpan(BASMALA_EN, 'Merciful');
    expect(span).not.toBeNull();
    expect(BASMALA_EN.slice(span!.start, span!.end)).toBe('Merciful');
    const lower = matchSpan(BASMALA_EN, 'merciful');
    expect(lower).toEqual(span);
  });

  it('keeps the arabic index searchable and the two locales separate', async () => {
    // EN is loaded, AR is not: an arabic query against EN still finds nothing.
    expect(searchAyahs('الله', 5, 'en')).toEqual([]);

    const records = await loadSearchIndex(); // default locale = ar
    expect(records).toHaveLength(6236);
    expect(ids(searchAyahs('الله', 50))).toContain('1:1');
    expect(ids(searchAyahs('الله', 50, 'ar'))).toContain('1:1');

    // An english query never leaks into the arabic index, nor the reverse.
    expect(searchAyahs('Most Merciful', 5, 'ar')).toEqual([]);
    expect(searchAyahs('الله', 5, 'en')).toEqual([]);
  });
});
