import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test('reciters browser: featured-first, surah play + download, snapshot fallback on API failure', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/reciters/');

  // Featured section first, in PM order (51 outranks 118 whose name sorts earlier).
  const featured = page.locator('#reciters-featured');
  await expect(featured).toBeVisible();
  await expect(page.locator('[data-reciter-row]').first()).toHaveAttribute('data-reciter-row', '51-5');
  await expect(featured.locator('[data-reciter-row]')).toHaveCount(2);
  const first = featured.locator('[data-reciter-row="51-5"]');
  await expect(first.locator('.reciter-name')).toHaveText('مشاري العفاسي');
  await expect(first.locator('.reciter-moshaf')).toHaveText('حفص عن عاصم - مرتل');
  await expect(featured.locator('[data-reciter-row]').nth(1)).toHaveAttribute('data-reciter-row', '118-1');

  // ClientRouter re-entry: leave and return in-session; the swapped-in shell must re-render and stay wired.
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran**');
  await page.locator('header a[href="/reciters"]').click();
  await page.waitForURL('**/reciters**');
  await expect(featured).toBeVisible();
  await expect(featured).toContainText('مشاري العفاسي');
  expect(await featured.locator('[data-reciter-row]').count()).toBeGreaterThan(0);
  await featured.locator('[data-reciter-row="51-5"] [data-reciter-play]').click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="title"]')).toHaveText('مشاري العفاسي');

  const all = page.locator('#reciters-all');
  await all.locator('summary').click();
  await expect(all.locator('[data-reciter-row="999-1"]')).toBeVisible();
  await expect(all.locator('[data-reciter-row="51-5"]')).toHaveCount(0);

  const sublist = first.locator('.surah-sublist');
  await expect(sublist).toBeHidden();
  await first.locator('[data-reciter-toggle]').click();
  await expect(first.locator('[data-reciter-toggle]')).toHaveAttribute('aria-expanded', 'true');
  const surahRows = first.locator('[data-surah-row]');
  await expect(surahRows).toHaveCount(3);
  await expect(surahRows.nth(0)).toHaveAttribute('data-surah-row', '1');
  await expect(surahRows.nth(1)).toHaveAttribute('data-surah-row', '2');
  await expect(surahRows.nth(2)).toHaveAttribute('data-surah-row', '18');
  await expect(surahRows.nth(0)).toContainText('الفاتحة');

  const download = first.locator('[data-surah-row="1"] [data-surah-download]');
  await expect(download).toHaveAttribute('href', 'https://cdn.mp3quran.net/a/afasy/r1/001.mp3');
  await expect(download).toHaveAttribute('target', '_blank');
  await expect(download).toHaveAttribute('rel', 'noopener');

  await first.locator('[data-surah-row="1"] [data-reciter-play]').click();
  await expect(bar).toBeVisible();
  await expect(page.locator('body')).toHaveClass(/has-player/);
  await expect(bar.locator('[data-qy="title"]')).toHaveText('مشاري العفاسي');
  await expect(bar.locator('[data-qy="reciter"]')).toHaveText('حفص عن عاصم - مرتل');

  // API dies on reload -> the committed snapshot still fills the featured section.
  await page.unroute('**/mp3quran.net/api/v3/reciters**');
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ status: 500 }));
  await page.reload();
  const featuredAfter = page.locator('#reciters-featured [data-reciter-row]');
  await expect(featuredAfter.first()).toBeVisible();
  expect(await featuredAfter.count()).toBeGreaterThan(2);
  await expect(page.locator('#reciters-featured')).toContainText('مشاري العفاسي');
});
