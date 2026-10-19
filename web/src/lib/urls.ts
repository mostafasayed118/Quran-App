import type { Locale } from './strings';

export const SITE = 'https://quranyahdi.pages.dev';

export function surahUrl(locale: Locale, n: number, ayah?: number): string {
  const base = `${SITE}${locale === 'en' ? '/en' : ''}/surah/${n}`;
  return ayah === undefined ? base : `${base}#ayah-${ayah}`;
}
