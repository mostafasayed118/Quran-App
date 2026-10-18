import { describe, it, expect } from 'vitest';
import { surahDisplayName } from '../../src/lib/surah-name';

describe('surahDisplayName', () => {
  const s = { nameAr: 'الفاتحة', nameEn: 'Al-Fatihah' };
  it('returns the Arabic name for ar', () => {
    expect(surahDisplayName(s, 'ar')).toBe('الفاتحة');
  });
  it('returns the English name for en', () => {
    expect(surahDisplayName(s, 'en')).toBe('Al-Fatihah');
  });
  it('falls back to the Arabic name when nameEn is missing or empty', () => {
    expect(surahDisplayName({ nameAr: 'الفاتحة' }, 'en')).toBe('الفاتحة');
    expect(surahDisplayName({ nameAr: 'الفاتحة', nameEn: '' }, 'en')).toBe('الفاتحة');
  });
  it('keeps the Arabic name for ar even with an English name present', () => {
    expect(surahDisplayName({ nameAr: 'البقرة', nameEn: 'Al-Baqarah' }, 'ar')).toBe('البقرة');
  });
});
