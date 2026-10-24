import { describe, it, expect } from 'vitest';
import { altLocalePath, GITHUB_RELEASES_URL, LANDING } from '../../src/lib/landing-content';

interface TextEntry {
  path: string;
  value: string;
}
function stringsOf(value: unknown, path = ''): TextEntry[] {
  if (typeof value === 'string') return [{ path, value }];
  if (Array.isArray(value)) return value.flatMap((v, i) => stringsOf(v, `${path}[${i}]`));
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([k, v]) => stringsOf(v, path ? `${path}.${k}` : k));
  }
  return [];
}

describe('altLocalePath', () => {
  it('prefixes AR paths for en', () => {
    expect(altLocalePath('/quran', 'en')).toBe('/en/quran/');
    expect(altLocalePath('/surah/2', 'en')).toBe('/en/surah/2/');
  });
  it('strips the en prefix for ar', () => {
    expect(altLocalePath('/en/quran', 'ar')).toBe('/quran/');
    expect(altLocalePath('/en/surah/2', 'ar')).toBe('/surah/2/');
  });
  it('maps both homes', () => {
    expect(altLocalePath('/', 'en')).toBe('/en/');
    expect(altLocalePath('/en/', 'ar')).toBe('/');
    expect(altLocalePath('/en', 'ar')).toBe('/');
  });
  it('keeps paths unchanged when already in the target locale', () => {
    expect(altLocalePath('/', 'ar')).toBe('/');
    expect(altLocalePath('/quran', 'ar')).toBe('/quran');
    expect(altLocalePath('/en/', 'en')).toBe('/en/');
    expect(altLocalePath('/en/quran', 'en')).toBe('/en/quran');
  });
  it('treats only the /en segment as the en prefix', () => {
    expect(altLocalePath('/enigma', 'ar')).toBe('/enigma');
    expect(altLocalePath('/enigma', 'en')).toBe('/en/enigma/');
  });
  it('falls back to the target locale home for non-absolute input', () => {
    expect(altLocalePath('quran', 'en')).toBe('/en/');
    expect(altLocalePath('', 'ar')).toBe('/');
    expect(altLocalePath('https://x.dev/y', 'en')).toBe('/en/');
  });
});

describe('LANDING copy (both locales)', () => {
  it('matches the exact LandingCopy shape', () => {
    for (const copy of [LANDING.ar, LANDING.en]) {
      expect(Object.keys(copy).sort()).toEqual(['about', 'cta', 'features', 'hero', 'promise']);
      expect(Object.keys(copy.hero).sort()).toEqual([
        'ayah',
        'ayahRef',
        'ctaPrimary',
        'ctaSecondary',
        'kicker',
        'lead',
      ]);
      expect(Object.keys(copy.about).sort()).toEqual(['bullets', 'story']);
      expect(Object.keys(copy.cta).sort()).toEqual([
        'githubLabel',
        'lead',
        'playLabel',
        'title',
        'version',
      ]);
    }
  });

  it('has exactly 14 feature rows in both locales', () => {
    expect(LANDING.ar.features.length).toBe(14);
    expect(LANDING.en.features.length).toBe(14);
    for (const f of [...LANDING.ar.features, ...LANDING.en.features]) {
      expect(Object.keys(f).sort()).toEqual(['desc', 'title']);
    }
  });

  it('has identical string structure, aligned index-by-index, all non-empty', () => {
    const ar = stringsOf(LANDING.ar);
    const en = stringsOf(LANDING.en);
    expect(en.map((e) => e.path)).toEqual(ar.map((e) => e.path));
    for (const { path, value } of ar) {
      expect(value.trim().length, `ar.${path}`).toBeGreaterThan(0);
    }
    for (const { path, value } of en) {
      expect(value.trim().length, `en.${path}`).toBeGreaterThan(0);
    }
  });

  it('has at least 3 promise items in both locales', () => {
    expect(LANDING.ar.promise.length).toBeGreaterThanOrEqual(3);
    expect(LANDING.en.promise.length).toBe(LANDING.ar.promise.length);
  });

  it('exposes the GitHub Releases URL', () => {
    expect(GITHUB_RELEASES_URL).toBe(
      'https://github.com/mostafasayed118/Quran-App/releases/latest',
    );
  });
});
