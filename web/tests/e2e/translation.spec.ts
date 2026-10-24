import { test, expect } from '@playwright/test';

test('EN surah pages pre-render the Pickthall translation', async ({ page }) => {
  await page.goto('/en/surah/1/');
  await expect(page.locator('.ayah-tr').first()).toContainText('In the name of Allah');
});

test('AR surah pages carry no translation', async ({ page }) => {
  await page.goto('/surah/1/');
  await expect(page.locator('.ayah-tr')).toHaveCount(0);
});

test('mushaf pages layout hides the translation', async ({ page }) => {
  await page.goto('/en/surah/1/');
  const first = page.locator('.ayah-tr').first();
  await expect(first).toBeVisible();
  await page.locator('[data-qy-layout="pages"]').click();
  await expect(page.locator('html')).toHaveAttribute('data-reader-layout', 'pages');
  await expect(page.locator('.ayah-tr:visible')).toHaveCount(0);
});
