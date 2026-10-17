import { test, expect } from '@playwright/test';

test('home renders RTL with chrome and toggles theme', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'day');
  await page.getByRole('button', { name: 'الوضع الليلي' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'night');
  await expect(page.getByRole('button', { name: 'الوضع النهاري' })).toBeVisible();
});
