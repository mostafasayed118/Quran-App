import { describe, it, expect } from 'vitest';
import { digitsFor, toArabicDigits, toAsciiDigits } from '../../src/lib/arabic-digits';

describe('digitsFor', () => {
  it('renders Arabic-Indic numerals for ar', () => {
    expect(digitsFor(2, 'ar')).toBe('٢');
    expect(digitsFor('114', 'ar')).toBe('١١٤');
  });
  it('renders Western numerals for en', () => {
    expect(digitsFor(2, 'en')).toBe('2');
    expect(digitsFor('114', 'en')).toBe('114');
  });
  it('matches the shared alphabet used by toArabicDigits for ar', () => {
    for (let n = 0; n <= 9; n += 1) expect(digitsFor(n, 'ar')).toBe(toArabicDigits(n));
    expect(digitsFor(6236, 'ar')).toBe('٦٢٣٦');
  });
  it('passes caller zero-padding through untouched for en', () => {
    expect(digitsFor('05', 'en')).toBe('05');
    expect(toAsciiDigits(digitsFor('05', 'ar'))).toBe('05');
  });
});
