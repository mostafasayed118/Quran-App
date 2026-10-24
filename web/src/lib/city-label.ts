import type { Locale } from './strings';

/** The minimum city shape needed for a display label (no data import). */
export interface CityName {
  id: string;
  nameAr: string;
  nameEn: string;
}

// Cities whose bare name is ambiguous; their label carries the country.
const COUNTRY: Record<string, { ar: string; en: string }> = {
  'lb-tripoli': { ar: 'لبنان', en: 'Lebanon' },
  'ly-tripoli': { ar: 'ليبيا', en: 'Libya' },
};

/** The localized display label of a city, disambiguating same-name cities. */
export function cityLabel(city: CityName, locale: Locale): string {
  const name = locale === 'en' ? city.nameEn : city.nameAr;
  const country = COUNTRY[city.id];
  return country === undefined ? name : `${name} (${country[locale]})`;
}
