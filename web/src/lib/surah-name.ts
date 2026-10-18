import type { Locale } from './strings';

export interface SurahNameLike {
  nameAr: string;
  nameEn?: string;
}

/** EN chrome uses the Western name when available; AR always keeps the Arabic script. */
export function surahDisplayName(s: SurahNameLike, locale: Locale): string {
  return locale === 'en' && s.nameEn ? s.nameEn : s.nameAr;
}
