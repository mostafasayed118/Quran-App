export const SITE = 'https://quranyahdi.pages.dev';
export function surahUrl(n: number, ayah?: number): string {
  const base = `${SITE}/surah/${n}`;
  return ayah === undefined ? base : `${base}#ayah-${ayah}`;
}
