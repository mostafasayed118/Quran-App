import { describe, it, expect } from 'vitest';
import { cityLabel, getCities } from '../../src/lib/cities';

const cities = getCities();

function byId(id: string) {
  const city = cities.find((c) => c.id === id);
  if (city === undefined) throw new Error(`missing city: ${id}`);
  return city;
}

describe('cityLabel', () => {
  it('indexes 156 cities', () => {
    expect(cities).toHaveLength(156);
  });

  it('disambiguates both Tripolis in Arabic and English', () => {
    const lb = cityLabel(byId('lb-tripoli'), 'ar');
    const ly = cityLabel(byId('ly-tripoli'), 'ar');
    expect(lb).toBe('طرابلس (لبنان)');
    expect(ly).toBe('طرابلس (ليبيا)');
    expect(lb).not.toBe(ly);

    const lbEn = cityLabel(byId('lb-tripoli'), 'en');
    const lyEn = cityLabel(byId('ly-tripoli'), 'en');
    expect(lbEn).toBe('Tripoli (Lebanon)');
    expect(lyEn).toBe('Tripoli (Libya)');
    expect(lbEn).not.toBe(lyEn);
  });

  it('leaves an unambiguous city unchanged', () => {
    expect(cityLabel(byId('eg-cairo'), 'ar')).toBe('القاهرة');
    expect(cityLabel(byId('eg-cairo'), 'en')).toBe('Cairo');
  });

  it('yields a non-empty label for every city in both locales', () => {
    for (const city of cities) {
      expect(cityLabel(city, 'ar').trim().length, `ar:${city.id}`).toBeGreaterThan(0);
      expect(cityLabel(city, 'en').trim().length, `en:${city.id}`).toBeGreaterThan(0);
    }
  });
});
