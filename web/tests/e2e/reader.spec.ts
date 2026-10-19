import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };
import surahsData from '../../src/data/surahs.json' with { type: 'json' };
import baqara from '../../src/data/ayahs/2.json' with { type: 'json' };
import { toArabicDigits } from '../../src/lib/arabic-digits';
import { t } from '../../src/lib/strings';

test.beforeEach(async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
});

test('surah 2 renders 286 ayahs with anchors and the real quran font', async ({ page }) => {
  await page.goto('/surah/2');
  await expect(page.locator('.ayah')).toHaveCount(286);
  await expect(page.locator('#ayah-255')).toHaveCount(1);
  await expect(page).toHaveTitle(/سورة البقرة/);
  const fontReady = await page.evaluate(async () => {
    await document.fonts.ready;
    return document.fonts.check('16px HafsSmart');
  });
  expect(fontReady).toBe(true);
});

test('prev/next edges', async ({ page }) => {
  await page.goto('/surah/1');
  await expect(page.getByRole('link', { name: 'كل السور' })).toBeVisible();
  await page.goto('/surah/114');
  await expect(page.getByRole('link', { name: 'السورة السابقة' })).toBeVisible();
});

test('ayah exposes plain Arabic to AT and Arabic digits in meta', async ({ page }) => {
  await page.goto('/surah/2/');
  const first = page.locator('.ayah').first();
  await expect(first.locator('.ayah-i')).toHaveText(/^[^\uE000-\uF8FF]+$/); // sr-only text is plain Arabic — no PUA glyphs
  await expect(first.locator('.ayah-u')).toHaveAttribute('aria-hidden', 'true');
  await expect(page.locator('.reader-head .meta')).toContainText('٢٨٦'); // Arabic-Indic, was 286
});

test('imlaei toggle swaps the visible span and persists', async ({ page }) => {
  await page.goto('/surah/1/');
  await page.getByRole('button', { name: 'إملائي' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-reading-view', 'imlaei');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-reading-view', 'imlaei');
});

test('reader boot script re-applies seeded settings right after SPA entry', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:reader', JSON.stringify({ view: 'imlaei', fontStep: 2 }));
  });
  await page.goto('/quran');
  await page.locator('.surah-list a[href="/surah/1/"]').click();
  await page.waitForURL('**/surah/1**');
  await expect(page.locator('html')).toHaveAttribute('data-reading-view', 'imlaei');
  const step = await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue('--reader-step').trim());
  expect(step).toBe('2');
});

test('reader records the topmost visible ayah as the qy:last-read resume point', async ({ page }) => {
  await page.goto('/surah/2/');
  await page.waitForFunction(() => {
    try {
      const p = JSON.parse(localStorage.getItem('qy:last-read') ?? 'null');
      return p !== null && p.s === 2 && Number.isInteger(p.a) && p.a >= 1;
    } catch {
      return false;
    }
  });
  const initial = await page.evaluate(() => (JSON.parse(localStorage.getItem('qy:last-read')!) as { a: number }).a);
  await page.locator('#ayah-50').scrollIntoViewIfNeeded();
  await page.waitForFunction((prev) => {
    try {
      const p = JSON.parse(localStorage.getItem('qy:last-read') ?? 'null');
      return p !== null && Number.isInteger(p.a) && p.a > prev;
    } catch {
      return false;
    }
  }, initial);
  const resumed = await page.evaluate(() => JSON.parse(localStorage.getItem('qy:last-read')!) as { s: number; a: number });
  expect(resumed.s).toBe(2);
  expect(resumed.a).toBeGreaterThan(initial);
});

test('a pending resume flush cannot overwrite the next surah after a ClientRouter swap', async ({ page }) => {
  await page.goto('/surah/2/');
  await page.evaluate(() => {
    const w = window as Window & { __qySamples?: (string | null)[] };
    w.__qySamples = [];
    window.setInterval(() => {
      try {
        w.__qySamples?.push(localStorage.getItem('qy:last-read'));
      } catch {
        /* storage unavailable */
      }
    }, 50);
  });
  await page.locator('#ayah-100').scrollIntoViewIfNeeded(); // arms the ~1s flush
  await page.locator('.reader-nav a[href="/surah/3/"]').click(); // SPA swap inside that throttle window
  await page.waitForURL('**/surah/3**');
  await page.waitForTimeout(2000); // covers any stale flush plus the new observer's first flush
  const points = await page.evaluate(() => {
    const w = window as Window & { __qySamples?: (string | null)[] };
    return (w.__qySamples ?? []).map((raw) => {
      try {
        return JSON.parse(raw ?? 'null') as { s?: number } | null;
      } catch {
        return null;
      }
    });
  });
  const firstThree = points.findIndex((p) => p?.s === 3);
  expect(firstThree).toBeGreaterThanOrEqual(0);
  expect(points.slice(firstThree).some((p) => p?.s === 2)).toBe(false);
});

test('mushaf pages layout renders page cards and navigates', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:reader', JSON.stringify({ layout: 'pages' }));
  });
  const surah2 = (
    surahsData as { surahs: ReadonlyArray<{ id: number; pagesStart: number; pagesEnd: number }> }
  ).surahs.find((s) => s.id === 2)!;
  const total = surah2.pagesEnd - surah2.pagesStart + 1;
  const firstOfPage = (p: number) => baqara.ayahs.find((a) => a.page === p)!.n;

  await page.goto('/surah/2');
  await expect(page.locator('.mushaf-page')).toHaveCount(total);
  const shown = page.locator('.mushaf-page:not([hidden])');
  await expect(shown).toHaveCount(1);
  await expect(shown).toHaveAttribute('data-page', String(surah2.pagesStart));
  await expect(
    page.getByRole('button', { name: t('ar', 'readerLayoutPages') }),
  ).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('[data-mushaf="prev"]')).toBeDisabled();
  await expect(page.locator('[data-mushaf="pos"]')).toHaveText(
    t('ar', 'readerPageOf')
      .replace('{x}', toArabicDigits(surah2.pagesStart))
      .replace('{y}', toArabicDigits(total)),
  );

  await page.locator('[data-mushaf="next"]').click();
  await expect(shown).toHaveAttribute('data-page', String(surah2.pagesStart + 1));
  await expect(page.locator('[data-mushaf="prev"]')).toBeEnabled();
  await expect
    .poll(() =>
      page.evaluate(
        () => JSON.parse(localStorage.getItem('qy:last-read') ?? 'null') as unknown,
      ),
    )
    .toEqual({ s: 2, a: firstOfPage(surah2.pagesStart + 1) });
});

test('pages layout honors the #ayah deep link', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:reader', JSON.stringify({ layout: 'pages' }));
  });
  const ayah200 = baqara.ayahs.find((a) => a.n === 200)!;

  await page.goto('/surah/2#ayah-200');
  await expect(page.locator('.mushaf-page:not([hidden])')).toHaveAttribute(
    'data-page',
    String(ayah200.page),
  );
  await expect(page.locator('#ayah-200')).toBeInViewport();
});
