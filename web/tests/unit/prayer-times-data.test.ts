import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const dataDir = fileURLToPath(new URL('../../public/data/prayer-times/', import.meta.url));
const read = (file: string): unknown => JSON.parse(readFileSync(dataDir + file, 'utf8'));

interface CityRef { id: string; nameAr: string; nameEn: string }
interface CityData {
  city: CityRef & { lat: number; lng: number; tz: string };
  months: { y: number; m: number; days: number[][] }[];
}

const assets = JSON.parse(
  readFileSync(fileURLToPath(new URL('../../../assets/data/cities.json', import.meta.url)), 'utf8'),
) as CityRef[];
const index = read('index.json') as { cities: CityRef[] };
const loadCity = (id: string): CityData => read(`${id}.json`) as CityData;
const day = (data: CityData, y: number, m: number, d: number): number[] =>
  data.months[(y - 2026) * 12 + (m - 1)].days[d - 1];

describe('prayer-times index', () => {
  it('lists all 156 cities in assets order with names intact', () => {
    expect(index.cities).toHaveLength(156);
    expect(index.cities.map((c) => c.id)).toEqual(assets.map((c) => c.id));
    for (const entry of index.cities) {
      expect(entry.nameAr.trim().length, entry.id).toBeGreaterThan(0);
      expect(entry.nameEn.trim().length, entry.id).toBeGreaterThan(0);
    }
  });
});

describe('sampled city (eg-cairo) covers 24 months', () => {
  const cairo = loadCity('eg-cairo');

  it('spans 2026-01 to 2027-12 with exact month lengths', () => {
    expect(cairo.months).toHaveLength(24);
    cairo.months.forEach((month, i) => {
      expect(month.y).toBe(2026 + Math.floor(i / 12));
      expect(month.m).toBe((i % 12) + 1);
      expect(month.days).toHaveLength(new Date(Date.UTC(month.y, month.m, 0)).getUTCDate());
    });
  });

  it('keeps per-day ordering, [0,1440) minutes and imsak = fajr - 10', () => {
    for (const month of cairo.months) {
      for (const row of month.days) {
        expect(row).toHaveLength(7);
        const [fajr, sunrise, dhuhr, asr, maghrib, isha, imsak] = row;
        expect(fajr).toBeLessThan(sunrise);
        expect(sunrise).toBeLessThan(dhuhr);
        expect(dhuhr).toBeLessThan(asr);
        expect(asr).toBeLessThan(maghrib);
        expect(maghrib).toBeLessThan(isha);
        for (const m of row) {
          expect(m).toBeGreaterThanOrEqual(0);
          expect(m).toBeLessThan(1440);
        }
        expect(imsak).toBe(fajr - 10);
      }
    }
  });
});

describe('whole corpus invariants', () => {
  it('every city/day is strictly ordered; minutes bounded; wrapped isha stored as 1440+min', () => {
    let wrapped = 0;
    for (const ref of index.cities) {
      const data = loadCity(ref.id);
      expect(data.city.id, ref.id).toBe(ref.id);
      expect(data.city.tz.trim().length, ref.id).toBeGreaterThan(0);
      expect(data.months, ref.id).toHaveLength(24);
      for (const month of data.months) {
        for (const row of month.days) {
          const [fajr, sunrise, dhuhr, asr, maghrib, isha, imsak] = row;
          const label = `${ref.id} ${month.y}-${month.m}`;
          expect(fajr, label).toBeLessThan(sunrise);
          expect(sunrise, label).toBeLessThan(dhuhr);
          expect(dhuhr, label).toBeLessThan(asr);
          expect(asr, label).toBeLessThan(maghrib);
          expect(maghrib, label).toBeLessThan(isha);
          expect(fajr, label).toBeGreaterThanOrEqual(10);
          expect(maghrib, label).toBeLessThan(1440);
          expect(isha, label).toBeLessThan(1440 + 360);
          expect(imsak, label).toBe(fajr - 10);
          if (isha >= 1440) wrapped += 1;
        }
      }
    }
    expect(wrapped).toBe(2308);
  });
});

describe('known-value pins (DST-aware city-local wall clock)', () => {
  it('Cairo winter (UTC+2) and summer (UTC+3 DST)', () => {
    expect(day(loadCity('eg-cairo'), 2026, 1, 1)).toEqual([319, 411, 720, 888, 1026, 1109, 309]);
    expect(day(loadCity('eg-cairo'), 2026, 6, 1)).toEqual([251, 354, 774, 989, 1192, 1283, 241]);
  });

  it('London: post-midnight isha stored as 1440+min (incl. the solstice overlap days)', () => {
    const london = loadCity('gb-london');
    expect(day(london, 2026, 5, 19)).toEqual([58, 303, 778, 1032, 1252, 1441, 48]);
    expect(day(london, 2026, 6, 22)).toEqual([62, 283, 784, 1045, 1282, 1503, 52]);
  });

  it('Mexico City keeps UTC-6 (no DST since 2022)', () => {
    expect(day(loadCity('mx-mexico-city'), 2026, 6, 1)).toEqual([268, 358, 755, 953, 1151, 1231, 258]);
  });
});
