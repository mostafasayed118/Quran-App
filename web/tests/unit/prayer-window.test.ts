import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const dataDir = fileURLToPath(new URL('../../public/data/prayer-times/', import.meta.url));
const read = (file: string): unknown => JSON.parse(readFileSync(dataDir + file, 'utf8'));

interface CityRef {
  id: string;
}
interface MonthRef {
  y: number;
  m: number;
}

const index = read('index.json') as { cities: CityRef[] };
const cairo = read('eg-cairo.json') as { months: MonthRef[] };

const now = new Date();
const monthStart = (y: number, m: number): Date => new Date(y, m - 1, 1);
const monthStartFromNow = (offset: number): Date =>
  new Date(now.getFullYear(), now.getMonth() + offset, 1);

describe('prayer-times window freshness', () => {
  it('ships the sampled city in the index', () => {
    expect(index.cities.some((city) => city.id === 'eg-cairo')).toBe(true);
  });

  it('ends at least three months after the current month', () => {
    const last = cairo.months[cairo.months.length - 1];
    const message =
      `Prayer-times window ends ${last.y}-${last.m}. Bump startYear/endYear in ` +
      'tools/export_web_prayer_times.dart, regenerate with TZ=UTC, and commit.';
    expect(monthStart(last.y, last.m).getTime(), message).toBeGreaterThanOrEqual(
      monthStartFromNow(3).getTime(),
    );
  });

  it('starts no later than the current month', () => {
    const first = cairo.months[0];
    expect(monthStart(first.y, first.m).getTime()).toBeLessThanOrEqual(
      monthStartFromNow(0).getTime(),
    );
  });
});
