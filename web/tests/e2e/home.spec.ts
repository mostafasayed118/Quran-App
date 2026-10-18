import { test, expect } from '@playwright/test';

test('home renders RTL with chrome and toggles theme', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'day');
  await page.getByRole('button', { name: 'الوضع الليلي' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'night');
  await expect(page.getByRole('button', { name: 'الوضع النهاري' })).toBeVisible();
});

test('theme toggle stays bound after ClientRouter navigation', async ({ page }) => {
  await page.goto('/');
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran**');
  await page.locator('.surah-list a[href="/surah/1"]').click();
  await page.waitForURL('**/surah/1**');
  await page.locator('.theme-toggle').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'night');
});
