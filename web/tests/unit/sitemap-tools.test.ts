import { describe, it, expect } from 'vitest';
import { buildSitemapUrls, toSitemapXml } from '../../src/lib/sitemap';

const SITE = 'https://quranyahdi.pages.dev';
const IDS = [1, 2];

describe('sitemap tool extras (WW1)', () => {
  it('appends extra paths after the surah pages with mirrored EN alternates', () => {
    const extras = ['/prayer-times/', '/prayer-times/eg-cairo/', '/qibla/'];
    const entries = buildSitemapUrls(SITE, IDS, extras);
    expect(entries).toHaveLength(5 + IDS.length + extras.length);
    expect(entries.slice(-3).map((e) => e.loc)).toEqual([
      `${SITE}/prayer-times/`,
      `${SITE}/prayer-times/eg-cairo/`,
      `${SITE}/qibla/`,
    ]);
    for (const entry of entries.slice(-3)) {
      expect(entry.alternates.ar).toBe(entry.loc);
      expect(entry.alternates.en).toBe(`${SITE}/en${entry.loc.slice(SITE.length)}`);
    }
  });

  it('keeps the exact pre-tools behaviour when no extras are passed', () => {
    expect(buildSitemapUrls(SITE, IDS)).toEqual(buildSitemapUrls(SITE, IDS, []));
    expect(buildSitemapUrls(SITE, IDS)).toHaveLength(5 + IDS.length);
  });

  it('emits the extras into the XML with alternates', () => {
    const xml = toSitemapXml(buildSitemapUrls(SITE, IDS, ['/prayer-times/']));
    expect(xml).toContain(`<loc>${SITE}/prayer-times/</loc>`);
    expect(xml).toContain(`hreflang="en" href="${SITE}/en/prayer-times/"`);
    expect(xml.match(/<url>/g)).toHaveLength(5 + IDS.length + 1);
  });
});
