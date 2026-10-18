import { test, expect } from '@playwright/test';

test('unknown route serves the localized 404 page, not the home fallback', async ({ page }) => {
  const response = await page.goto('/definitely-missing');

  expect(response?.status()).toBe(404);

  const marker = page.locator('[data-qy="not-found"]');
  await expect(marker).toBeVisible();
  await expect(marker.locator('h1')).toHaveText('الصفحة غير موجودة');

  const searchCta = page.getByRole('link', { name: 'ابحث في المصحف' });
  await expect(searchCta).toBeVisible();
  await expect(searchCta).toHaveAttribute('href', '/quran/');

  const homeCta = page.getByRole('link', { name: 'الصفحة الرئيسية' });
  await expect(homeCta).toBeVisible();
  await expect(homeCta).toHaveAttribute('href', '/');

  await expect(marker.locator('[dir="ltr"]')).toHaveText('Page not found');

  // The P2 soft-404 (home page fallback) must be gone.
  await expect(page.locator('.hero')).toHaveCount(0);
  await expect(page.locator('[data-qy="resume-mount"]')).toHaveCount(0);
});
