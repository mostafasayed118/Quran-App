import { test, expect } from '@playwright/test';

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
