import { describe, it, expect } from 'vitest';
import { altLocalePath } from '../../src/lib/landing-content';

describe('altLocalePath', () => {
  it('prefixes AR paths for en', () => {
    expect(altLocalePath('/quran', 'en')).toBe('/en/quran');
    expect(altLocalePath('/surah/2', 'en')).toBe('/en/surah/2');
  });
  it('strips the en prefix for ar', () => {
    expect(altLocalePath('/en/quran', 'ar')).toBe('/quran');
    expect(altLocalePath('/en/surah/2', 'ar')).toBe('/surah/2');
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
    expect(altLocalePath('/enigma', 'en')).toBe('/en/enigma');
  });
  it('falls back to the target locale home for non-absolute input', () => {
    expect(altLocalePath('quran', 'en')).toBe('/en/');
    expect(altLocalePath('', 'ar')).toBe('/');
    expect(altLocalePath('https://x.dev/y', 'en')).toBe('/en/');
  });
});
