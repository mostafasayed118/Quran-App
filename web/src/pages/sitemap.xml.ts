import type { APIRoute } from 'astro';
import { getSurahs } from '../lib/surahs';
import { getCities } from '../lib/cities';
import { buildSitemapUrls, dualLocaleEntries, toSitemapXml } from '../lib/sitemap';

export const GET: APIRoute = ({ site }) => {
  const ids = getSurahs().map((s) => s.id);
  const extras = [
    '/prayer-times/',
    ...getCities().map((c) => `/prayer-times/${c.id}/`),
    '/qibla/',
  ];
  const xml = toSitemapXml(dualLocaleEntries(buildSitemapUrls(site!.href, ids, extras)));
  return new Response(xml, { headers: { 'Content-Type': 'application/xml' } });
};
