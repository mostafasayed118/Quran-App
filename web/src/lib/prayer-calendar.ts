/**
 * The calendar helpers of the prayer-times pages.
 *
 * They live here (and not in `prayer-times.ts`) so the page's client script can
 * use them without pulling the generated per-city JSON into the browser bundle:
 * `prayer-times.ts` resolves every city file at build time.
 */
import { t, MONTH_KEYS, type Locale } from './strings';
import { digitsFor } from './arabic-digits';

/** One month of prayer times: `days[d]` is [fajr, sunrise, dhuhr, asr, maghrib, isha, imsak]. */
export interface PrayerMonth {
  y: number;
  m: number;
  days: number[][];
}

/** The year range the shipped dataset covers, derived from the data itself. */
export function getPrayerTimesYearRange(months: readonly PrayerMonth[]): {
  minYear: number;
  maxYear: number;
} {
  let minYear = Number.POSITIVE_INFINITY;
  let maxYear = Number.NEGATIVE_INFINITY;
  for (const month of months) {
    if (month.y < minYear) minYear = month.y;
    if (month.y > maxYear) maxYear = month.y;
  }
  return { minYear, maxYear };
}

/** The month name of the prayer-times select, e.g. "يناير ٢٠٢٦" / "January 2026". */
export function monthLabel(locale: Locale, y: number, m: number): string {
  const name = t(locale, MONTH_KEYS[m - 1] ?? MONTH_KEYS[0]);
  return locale === 'en' ? `${name} ${y}` : `${name} ${digitsFor(y, 'ar')}`;
}

/** Minutes since local midnight → the wall clock; an isha past midnight wraps to 00:xx. */
export function wrapMinutes(min: number): number {
  return ((min % 1440) + 1440) % 1440;
}

/** Minutes since local midnight → the localized HH:MM of the day. */
export function formatClock(min: number, locale: Locale): string {
  const m = wrapMinutes(min);
  return digitsFor(
    `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`,
    locale,
  );
}

export interface TodayResolution {
  /** The year of "today" (the build date on the server). */
  y: number;
  /** The month of "today", 1-12. */
  m: number;
  /** The day of "today", 1-31. */
  d: number;
  /** True when "today" falls inside the shipped dataset's year window. */
  inRange: boolean;
  /** The index of today's month in the dataset (0 when out of range). */
  monthIndex: number;
}

/**
 * Where "today" sits in the shipped dataset.
 *
 * The dataset defines its own window (tools/export_web_prayer_times.dart writes
 * 2026-01..2027-12 today), so the bounds come from the shipped months: a
 * regenerated dataset never needs a code change here.
 */
export function resolveToday(months: readonly PrayerMonth[], now: Date): TodayResolution {
  const y = now.getFullYear();
  const m = now.getMonth() + 1;
  const d = now.getDate();
  const { minYear, maxYear } = getPrayerTimesYearRange(months);
  const inRange = y >= minYear && y <= maxYear;
  const monthIndex = inRange
    ? Math.max(
        0,
        months.findIndex((mo) => mo.y === y && mo.m === m),
      )
    : 0;
  return { y, m, d, inRange, monthIndex };
}
