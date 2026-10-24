export type SitemapEntry = { loc: string; alternates: { ar: string; en: string } };

const STATIC_PATHS = ['/', '/quran/', '/reciters/', '/about/', '/privacy/'];

function enPath(path: string): string {
  return path === '/' ? '/en/' : `/en${path}`;
}

export function buildSitemapUrls(site: string, surahIds: number[], extras: string[] = []): SitemapEntry[] {
  const origin = site.replace(/\/+$/, '');
  const paths = [...STATIC_PATHS, ...surahIds.map((n) => `/surah/${n}/`), ...extras];
  return paths.map((path) => {
    const ar = `${origin}${path}`;
    return { loc: ar, alternates: { ar, en: `${origin}${enPath(path)}` } };
  });
}

/**
 * Expands AR-first entries so both locales get their own <loc>: each entry is
 * followed by a copy whose `loc` is its `alternates.en` (same alternates object).
 * Precondition: `loc` is the AR URL, as produced by `buildSitemapUrls`. An entry
 * that is already its own EN alternate (loc === alternates.en) is kept once.
 */
export function dualLocaleEntries(entries: SitemapEntry[]): SitemapEntry[] {
  return entries.flatMap((entry) =>
    entry.loc === entry.alternates.en
      ? [entry]
      : [entry, { loc: entry.alternates.en, alternates: entry.alternates }]
  );
}

const XML_ENTITIES: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&apos;',
};

function xmlEscape(value: string): string {
  return value.replace(/[&<>"']/g, (c) => XML_ENTITIES[c]);
}

export function toSitemapXml(entries: SitemapEntry[]): string {
  const urls = entries
    .map(
      (entry) => `  <url>
    <loc>${xmlEscape(entry.loc)}</loc>
    <xhtml:link rel="alternate" hreflang="ar" href="${xmlEscape(entry.alternates.ar)}" />
    <xhtml:link rel="alternate" hreflang="en" href="${xmlEscape(entry.alternates.en)}" />
    <xhtml:link rel="alternate" hreflang="x-default" href="${xmlEscape(entry.alternates.ar)}" />
  </url>`
    )
    .join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urls}
</urlset>
`;
}
