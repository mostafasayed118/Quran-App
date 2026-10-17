import { describe, it, expect } from 'vitest';
import { toArabicDigits } from '../../src/lib/arabic-digits';
import { surahUrl, SITE } from '../../src/lib/urls';
import { surahNeighbors } from '../../src/lib/surah-neighbors';

describe('toArabicDigits', () => {
  it('maps 0-9', () => expect(toArabicDigits(6236)).toBe('٦٢٣٦'));
  it('maps single digits', () => expect(toArabicDigits(255)).toBe('٢٥٥'));
});

describe('surahUrl', () => {
  it('builds surah url', () => expect(surahUrl(18)).toBe(`${SITE}/surah/18`));
  it('builds ayah anchor url', () => expect(surahUrl(2, 255)).toBe(`${SITE}/surah/2#ayah-255`));
});

describe('surahNeighbors', () => {
  it('first surah has no prev, has next 2', () => expect(surahNeighbors(1)).toEqual({ prev: null, next: 2 }));
  it('last surah has prev and no next', () => expect(surahNeighbors(114)).toEqual({ prev: 113, next: null }));
  it('middle surah has both', () => expect(surahNeighbors(18)).toEqual({ prev: 17, next: 19 }));
});
