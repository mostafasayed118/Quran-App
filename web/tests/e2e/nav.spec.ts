import { test, expect } from '@playwright/test';

test('AR header links to the qibla page and navigates to it', async ({ page }) => {
  await page.goto('/');
  const link = page.locator('header nav a[href="/qibla/"]');
  await expect(link).toBeVisible();
  await expect(link).toHaveText('القبلة');
  await link.click();
  await expect(page).toHaveURL('/qibla/');
  await expect(page.locator('h1')).toBeVisible();
});

test('EN header links to the qibla page and navigates to it', async ({ page }) => {
  await page.goto('/en/');
  const link = page.locator('header nav a[href="/en/qibla/"]');
  await expect(link).toBeVisible();
  await expect(link).toHaveText('Qibla');
  await link.click();
  await expect(page).toHaveURL('/en/qibla/');
});
