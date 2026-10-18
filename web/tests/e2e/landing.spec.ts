import { test, expect } from '@playwright/test';

test('landing renders the hero with the provisional ayah and both CTAs', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle('قرآن يَهدي');
  await expect(page.locator('.hero-ayah')).toBeVisible();
  await expect(page.locator('.hero-ayah')).toContainText('إِنَّ هَذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ');
  await expect(page.locator('.hero-ref')).toContainText('الإسراء ٩');
  await expect(page.locator('.hero a[href="/quran"]')).toBeVisible();
  await expect(page.locator('.hero a[href="/about"]')).toBeVisible();
});

test('landing shows the features heading, exactly 14 feature rows and the promise', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.features h2')).toBeVisible();
  await expect(page.locator('.feat-item')).toHaveCount(14);
  await expect(page.locator('.promise-item').first()).toBeVisible();
  expect(await page.locator('.promise-item').count()).toBeGreaterThanOrEqual(3);
});

test('landing nav points to the quran index and reciters', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('header a[href="/quran"]')).toHaveCount(1);
  await expect(page.locator('header a[href="/reciters"]')).toHaveCount(1);
});
