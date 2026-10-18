import type { APIRoute } from 'astro';
import surahs from '../data/surahs.json';
import { buildSitemapUrls, toSitemapXml } from '../lib/sitemap';

export const GET: APIRoute = ({ site }) => {
  const ids = surahs.surahs.map((s) => s.id);
  const xml = toSitemapXml(buildSitemapUrls(site!.href, ids));
  return new Response(xml, { headers: { 'Content-Type': 'application/xml' } });
};
