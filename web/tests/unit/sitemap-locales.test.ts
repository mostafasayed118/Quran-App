import { describe, it, expect } from 'vitest';
import { buildSitemapUrls, dualLocaleEntries } from '../../src/lib/sitemap';

const SITE = 'https://quranyahdi.pages.dev';

describe('dual locale sitemap entries', () => {
  it('expands an AR entry into AR then EN, sharing the same alternates object', () => {
    const entry = {
      loc: `${SITE}/quran/`,
      alternates: { ar: `${SITE}/quran/`, en: `${SITE}/en/quran/` },
    };
    const entries = dualLocaleEntries([entry]);
    expect(entries).toHaveLength(2);
    expect(entries.map((e) => e.loc)).toEqual([`${SITE}/quran/`, `${SITE}/en/quran/`]);
    expect(entries[0]).toBe(entry);
    expect(entries[1].alternates).toBe(entry.alternates);
  });

  it('maps the home entry to /en/', () => {
    const [home] = buildSitemapUrls(SITE, []);
    const entries = dualLocaleEntries([home]);
    expect(entries.map((e) => e.loc)).toEqual([`${SITE}/`, `${SITE}/en/`]);
  });

  it('does not duplicate an entry that is already its own EN alternate', () => {
    const enOnly = { loc: `${SITE}/en/`, alternates: { ar: `${SITE}/`, en: `${SITE}/en/` } };
    expect(dualLocaleEntries([enOnly])).toEqual([enOnly]);
  });

  it('preserves order across the full build and doubles the count', () => {
    const base = buildSitemapUrls(SITE, [1], ['/prayer-times/']);
    const entries = dualLocaleEntries(base);
    expect(entries).toHaveLength(base.length * 2);
    expect(entries.map((e) => e.loc)).toEqual(
      base.flatMap((e) => [e.alternates.ar, e.alternates.en])
    );
  });
});
