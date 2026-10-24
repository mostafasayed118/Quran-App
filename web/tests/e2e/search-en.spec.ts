import { test, expect } from '@playwright/test';

test.describe.configure({ timeout: 60_000 });

test('EN index verse search finds 1:1 under /en/surah/', async ({ page }) => {
  await page.goto('/en/quran');
  await page
    .locator('[data-qy="surah-index"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  await expect(async () => {
    await page.locator('.index-search').fill('Merciful');
    await expect(page.locator('.ayah-hits a[href="/en/surah/1/#ayah-1"]')).toBeVisible();
  }).toPass({ timeout: 10_000 });

  const hrefs = await page
    .locator('.ayah-hits a')
    .evaluateAll((links) => links.map((link) => link.getAttribute('href') ?? ''));
  expect(hrefs.length).toBeGreaterThan(0);
  expect(hrefs.every((href) => href.startsWith('/en/surah/'))).toBe(true);
});

test('AR index verse search still finds 1:1 for الله', async ({ page }) => {
  await page.goto('/quran');
  await page
    .locator('[data-qy="surah-index"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  await expect(async () => {
    await page.locator('.index-search').fill('الله');
    await expect(page.locator('.ayah-hits a[href="/surah/1/#ayah-1"]')).toBeVisible();
  }).toPass({ timeout: 10_000 });
});
