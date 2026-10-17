import { test, expect } from '@playwright/test';

test('index lists 114 surahs and filters', async ({ page }) => {
  await page.goto('/quran');
  await expect(page.locator('.surah-list a')).toHaveCount(114);
  await page.getByRole('searchbox').fill('الكهف');
  await expect(page.locator('.surah-list a')).toHaveCount(1);
  await expect(page.locator('.surah-list a')).toHaveAttribute('href', '/surah/18');
});
