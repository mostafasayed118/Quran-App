import type { City } from './cities';
import type { PrayerMonth } from './prayer-calendar';

/** A city with the coordinates the Qibla bearing is computed from. */
export interface CityCoordinates extends City {
  lat: number;
  lng: number;
  tz: string;
}

// The month shape and the year range live in `prayer-calendar.ts` so the page's
// client script can use them without pulling every generated city file in.
export type { PrayerMonth } from './prayer-calendar';
export { getPrayerTimesYearRange } from './prayer-calendar';

export interface PrayerTimesData {
  city: CityCoordinates;
  months: PrayerMonth[];
}

/**
 * Every generated city file, resolved by Vite at build time.
 *
 * The glob replaces the five copies of
 * `readFileSync(join(process.cwd(), 'public', 'data', 'prayer-times', ...))` that
 * used to break whenever the build ran from a different working directory.
 */
const CITY_FILES = import.meta.glob('../../public/data/prayer-times/*.json', {
  eager: true,
  query: '?raw',
  import: 'default',
}) as Record<string, string>;

function rawFor(cityId: string): string | undefined {
  const suffix = `/prayer-times/${cityId}.json`;
  for (const [path, raw] of Object.entries(CITY_FILES)) {
    if (path.endsWith(suffix)) return raw;
  }
  return undefined;
}

/**
 * The prayer times of one city.
 *
 * `isha` is stored as 1440+minutes when it falls after local midnight; renderers
 * must apply `% 1440` to get the wall-clock time.
 */
export function getPrayerTimes(cityId: string): PrayerTimesData {
  const raw = rawFor(cityId);
  if (raw === undefined) throw new Error(`prayer-times data missing for ${cityId}`);
  return JSON.parse(raw) as PrayerTimesData;
}
