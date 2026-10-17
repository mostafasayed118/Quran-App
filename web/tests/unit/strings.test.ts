import { describe, it, expect } from 'vitest';
import { t, stringKeys, defaultLocale } from '../../src/lib/strings';

describe('strings', () => {
  it('defaults to Arabic', () => {
    expect(defaultLocale).toBe('ar');
  });
  it('has a non-empty value for every key in both locales', () => {
    for (const key of stringKeys) {
      expect(t('ar', key).trim().length, `ar:${key}`).toBeGreaterThan(0);
      expect(t('en', key).trim().length, `en:${key}`).toBeGreaterThan(0);
    }
  });
  it('ships the core chrome strings', () => {
    expect(t('ar', 'navQuran')).toBe('المصحف');
    expect(t('en', 'navQuran')).toBe('Quran');
    expect(t('ar', 'themeToNight')).toBe('الوضع الليلي');
    expect(t('en', 'themeToNight')).toBe('Night mode');
  });
});
