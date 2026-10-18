import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test('index lists 114 surahs and filters', async ({ page }) => {
  await page.goto('/quran');
  await expect(page.locator('.surah-list a')).toHaveCount(114);
  await page.getByRole('searchbox').fill('الكهف');
  await expect(page.locator('.surah-list a')).toHaveCount(1);
  await expect(page.locator('.surah-list a')).toHaveAttribute('href', '/surah/18');
});

test('digit-only query filters surahs without the verse area or an index fetch', async ({ page }) => {
  const indexRequests: string[] = [];
  page.on('request', (req) => {
    if (req.url().includes('search-index')) indexRequests.push(req.url());
  });
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('112');
  await expect(page.locator('.surah-list a')).toHaveCount(1);
  await expect(page.locator('.surah-list a').first()).toContainText('الإخلاص');
  await expect(page.locator('.ayah-search')).toHaveCount(0);
  expect(indexRequests).toHaveLength(0);
});

test('ayah search finds the Light verse and caps results at 50', async ({ page }) => {
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('الله نور السماوات');
  await expect(page.locator('.ayah-hits a[href="/surah/24#ayah-35"]')).toBeVisible();
  expect(await page.locator('.ayah-hits a').count()).toBeLessThanOrEqual(50);
});

test('ayah search load failure shows a retry that recovers', async ({ page }) => {
  await page.route('**/search-index*', (r) => r.abort());
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('الله نور السماوات');
  await expect(page.getByText('تعذر تحميل المحتوى')).toBeVisible();
  const retry = page.getByRole('button', { name: 'إعادة المحاولة' });
  await expect(retry).toBeVisible();
  await page.unroute('**/search-index*');
  await retry.click();
  await expect(page.locator('.ayah-hits a[href="/surah/24#ayah-35"]')).toBeVisible();
});

test('ayah hit deep-link scrolls to the target anchor under SPA navigation', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('الله نور السماوات');
  const hit = page.locator('.ayah-hits a[href="/surah/24#ayah-35"]');
  await expect(hit).toBeVisible();
  await hit.click();
  await page.waitForURL('**/surah/24**');
  await expect(page.locator('#ayah-35')).toBeInViewport();
});
