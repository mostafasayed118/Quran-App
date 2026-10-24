import type { APIRoute } from 'astro';
import { getSurahs } from '../lib/surahs';
import { getCities } from '../lib/cities';
import { buildSitemapUrls, dualLocaleEntries, toSitemapXml } from '../lib/sitemap';

export const GET: APIRoute = ({ site }) => {
  const ids = getSurahs().map((s) => s.id);
  const extras = ['/prayer-times/', ...getCities().map((c) => `/prayer-times/${c.id}/`), '/qibla/'];
  // The build/deploy date, not a per-page content-change date: one value for
  // every entry so the sitemap stays honest about what it actually knows.
  const lastmod = new Date().toISOString().slice(0, 10);
  const xml = toSitemapXml(
    dualLocaleEntries(
      buildSitemapUrls(site!.href, ids, extras).map((entry) => ({ ...entry, lastmod })),
    ),
  );
  return new Response(xml, { headers: { 'Content-Type': 'application/xml' } });
};
