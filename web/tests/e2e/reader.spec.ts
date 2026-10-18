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
