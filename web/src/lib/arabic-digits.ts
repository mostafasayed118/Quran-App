import type { Locale } from './strings';

const AR = '٠١٢٣٤٥٦٧٨٩';
export function toArabicDigits(n: number | string): string {
  return String(n).replace(/\d/g, (d) => AR[Number(d)]);
}
export function toAsciiDigits(s: string): string {
  return s.replace(/[٠-٩]/g, (d) => String(AR.indexOf(d)));
}
/** Locale-aware numerals: Arabic-Indic for ar, Western for en. Callers keep their own zero-padding. */
export function digitsFor(value: string | number, locale: Locale): string {
  return locale === 'ar' ? toArabicDigits(value) : String(value);
}
