import { describe, it, expect } from 'vitest';
import { normalizeArabic } from '../../src/lib/arabic';
import { toArabicDigits, toAsciiDigits } from '../../src/lib/arabic-digits';

describe('normalizeArabic', () => {
  it('strips tashkeel', () => {
    expect(normalizeArabic('الْكَهْف')).toBe('الكهف');
  });
  it('unifies hamza forms to bare alef', () => {
    expect(normalizeArabic('إسراء')).toBe('اسراء');
    expect(normalizeArabic('أرض')).toBe('ارض');
    expect(normalizeArabic('آية')).toBe('ايه');
    expect(normalizeArabic('ٱلرحمن')).toBe('الرحمن');
  });
  it('strips dagger alef, combining maddah and tatweel', () => {
    expect(normalizeArabic('ٱلرَّحْمَٰنِ')).toBe('الرحمن');
    expect(normalizeArabic('\u0627\u0653\u0644 \u0639\u0645\u0631\u0627\u0646')).toBe('ال عمران');
    expect(normalizeArabic('مـحـمـد')).toBe('محمد');
  });
  it('maps ta marbuta to ha and alef maqsura to ya', () => {
    expect(normalizeArabic('صلاة')).toBe('صلاه');
    expect(normalizeArabic('موسى')).toBe('موسي');
  });
  it('maps Arabic-Indic digits to ASCII', () => {
    expect(normalizeArabic('١٨')).toBe('18');
    expect(normalizeArabic('سورة ٣')).toBe('سوره 3');
  });
  it('trims and lowercases', () => {
    expect(normalizeArabic('  AL-KAHF  ')).toBe('al-kahf');
  });
  it('applies the full chain to mixed input', () => {
    expect(normalizeArabic('  سُورَةُ ٢٥  ')).toBe('سوره 25');
  });
});

describe('toAsciiDigits', () => {
  it('maps ٠-٩ to ASCII and leaves everything else untouched', () => {
    expect(toAsciiDigits('٠١٢٣٤٥٦٧٨٩')).toBe('0123456789');
    expect(toAsciiDigits('آية ٥')).toBe('آية 5');
  });
  it('round-trips with toArabicDigits on one shared alphabet', () => {
    for (let n = 0; n <= 9; n += 1) expect(toAsciiDigits(toArabicDigits(n))).toBe(String(n));
    expect(toArabicDigits(6236)).toBe('٦٢٣٦');
  });
});
