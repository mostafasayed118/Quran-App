import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { APIRoute } from 'astro';
import surahs from '../data/surahs.json';
import { buildSitemapUrls, toSitemapXml } from '../lib/sitemap';

// Prerender routes are bundled into chunks at build time, so import.meta.url
// no longer points at this file — resolve from the web/ cwd instead.
const cityIndex = JSON.parse(
  readFileSync(join(process.cwd(), 'public', 'data', 'prayer-times', 'index.json'), 'utf8'),
) as { cities: { id: string }[] };

export const GET: APIRoute = ({ site }) => {
  const ids = surahs.surahs.map((s) => s.id);
  const extras = [
    '/prayer-times/',
    ...cityIndex.cities.map((c) => `/prayer-times/${c.id}/`),
    '/qibla/',
  ];
  const xml = toSitemapXml(buildSitemapUrls(site!.href, ids, extras));
  return new Response(xml, { headers: { 'Content-Type': 'application/xml' } });
};
