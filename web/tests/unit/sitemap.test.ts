import { describe, it, expect } from 'vitest';
import surahs from '../../src/data/surahs.json';
import { buildSitemapUrls, toSitemapXml } from '../../src/lib/sitemap';

const SITE = 'https://quranyahdi.pages.dev';
const IDS = surahs.surahs.map((s) => s.id);

describe('sitemap urls', () => {
  it('covers the 5 static pages plus 114 surahs, each carrying alternates', () => {
    const entries = buildSitemapUrls(SITE, IDS);
    expect(entries).toHaveLength(119);
    const locs = entries.map((e) => e.loc);
    for (const path of ['/', '/quran/', '/reciters/', '/about/', '/privacy/']) {
      expect(locs).toContain(`${SITE}${path}`);
    }
    expect(locs).toContain(`${SITE}/surah/1/`);
    expect(locs).toContain(`${SITE}/surah/114/`);
    for (const entry of entries) {
      expect(entry.alternates.ar).toBe(entry.loc);
    }
  });

  it('every EN alternate mirrors its AR path (with /en/ for the home page)', () => {
    const entries = buildSitemapUrls(SITE, IDS);
    for (const entry of entries) {
      const path = entry.alternates.ar.slice(SITE.length);
      const expected = path === '/' ? '/en/' : `/en${path}`;
      expect(entry.alternates.en).toBe(`${SITE}${expected}`);
    }
    expect(entries.find((e) => e.alternates.ar === `${SITE}/`)?.alternates.en).toBe(`${SITE}/en/`);
    expect(entries.find((e) => e.alternates.ar === `${SITE}/surah/114/`)?.alternates.en).toBe(
      `${SITE}/en/surah/114/`,
    );
  });

  it('has no duplicate locs', () => {
    const locs = buildSitemapUrls(SITE, IDS).map((e) => e.loc);
    expect(new Set(locs).size).toBe(locs.length);
  });

  it('tolerates a trailing slash on the site origin', () => {
    expect(buildSitemapUrls(`${SITE}/`, IDS)).toEqual(buildSitemapUrls(SITE, IDS));
  });
});

describe('sitemap xml', () => {
  it('emits one <url> per entry with ar/en/x-default alternates pointing at the right urls', () => {
    const xml = toSitemapXml([
      {
        loc: `${SITE}/surah/114`,
        alternates: { ar: `${SITE}/surah/114`, en: `${SITE}/en/surah/114` },
      },
    ]);
    expect(xml).toContain(
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">',
    );
    expect(xml).toContain(`<loc>${SITE}/surah/114</loc>`);
    expect(xml).toContain(`<xhtml:link rel="alternate" hreflang="ar" href="${SITE}/surah/114" />`);
    expect(xml).toContain(
      `<xhtml:link rel="alternate" hreflang="en" href="${SITE}/en/surah/114" />`,
    );
    expect(xml).toContain(
      `<xhtml:link rel="alternate" hreflang="x-default" href="${SITE}/surah/114" />`,
    );
    expect(xml.match(/<url>/g)).toHaveLength(1);
  });

  it('escapes XML entities in loc and alternate hrefs', () => {
    const xml = toSitemapXml([
      {
        loc: 'https://example.com/a&b',
        alternates: { ar: 'https://example.com/a&b', en: 'https://example.com/a&b<c>' },
      },
    ]);
    expect(xml).toContain('https://example.com/a&amp;b');
    expect(xml).toContain('https://example.com/a&amp;b&lt;c&gt;');
    expect(xml).not.toMatch(/&(?!amp;|lt;|gt;|quot;|apos;)/);
  });
});
