import { toAsciiDigits } from './arabic-digits';

export function normalizeArabic(input: string): string {
  return toAsciiDigits(input)
    .trim()
    .toLowerCase()
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه');
}
