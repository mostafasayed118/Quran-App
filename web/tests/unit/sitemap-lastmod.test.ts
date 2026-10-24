import { describe, it, expect } from 'vitest';
import { dualLocaleEntries, toSitemapXml } from '../../src/lib/sitemap';

const SITE = 'https://quranyahdi.pages.dev';

describe('sitemap lastmod', () => {
  it('renders <lastmod> after <loc> when the entry carries one', () => {
    const xml = toSitemapXml([
      {
        loc: `${SITE}/surah/1/`,
        alternates: { ar: `${SITE}/surah/1/`, en: `${SITE}/en/surah/1/` },
        lastmod: '2026-10-24',
      },
    ]);
    expect(xml).toContain(`<loc>${SITE}/surah/1/</loc>`);
    expect(xml).toContain('<lastmod>2026-10-24</lastmod>');
    const locAt = xml.indexOf('<loc>');
    const lastmodAt = xml.indexOf('<lastmod>');
    const linkAt = xml.indexOf('<xhtml:link');
    expect(lastmodAt).toBeGreaterThan(locAt);
    expect(lastmodAt).toBeLessThan(linkAt);
    expect(xml.match(/<lastmod>/g)).toHaveLength(1);
  });

  it('renders no <lastmod> when the entry has none', () => {
    const xml = toSitemapXml([
      {
        loc: `${SITE}/quran/`,
        alternates: { ar: `${SITE}/quran/`, en: `${SITE}/en/quran/` },
      },
    ]);
    expect(xml).not.toContain('<lastmod>');
    expect(xml).toContain(
      `<loc>${SITE}/quran/</loc>\n    <xhtml:link rel="alternate" hreflang="ar"`,
    );
  });

  it('preserves lastmod on both the AR and the EN entry', () => {
    const entry = {
      loc: `${SITE}/surah/2/`,
      alternates: { ar: `${SITE}/surah/2/`, en: `${SITE}/en/surah/2/` },
      lastmod: '2026-10-24',
    };
    const entries = dualLocaleEntries([entry]);
    expect(entries).toHaveLength(2);
    expect(entries.map((e) => e.lastmod)).toEqual(['2026-10-24', '2026-10-24']);
    expect(entries[0]).toBe(entry);
    expect(entries[1].alternates).toBe(entry.alternates);
  });
});
