import { test, expect } from '@playwright/test';

test('AR home carries locale head and the language switch', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  expect(await page.locator('head link[rel="alternate"][hreflang]').count()).toBeGreaterThanOrEqual(1);
  const switchLink = page.locator('header .lang-switch');
  await expect(switchLink).toHaveText('English');
  await expect(switchLink).toHaveAttribute('href', '/en/');
  await expect(switchLink).toHaveAttribute('rel', 'alternate');
});
