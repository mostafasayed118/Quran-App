import { test, expect } from '@playwright/test';

test('index lists 114 surahs and filters', async ({ page }) => {
  await page.goto('/quran');
  await expect(page.locator('.surah-list a')).toHaveCount(114);
  await page.getByRole('searchbox').fill('الكهف');
  await expect(page.locator('.surah-list a')).toHaveCount(1);
  await expect(page.locator('.surah-list a')).toHaveAttribute('href', '/surah/18');
});

test('ayah search finds the Light verse and caps results at 50', async ({ page }) => {
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('الله نور السماوات');
  await expect(page.locator('.ayah-hits a[href="/surah/24#ayah-35"]')).toBeVisible();
  expect(await page.locator('.ayah-hits a').count()).toBeLessThanOrEqual(50);
});

test('ayah search load failure shows a retry that recovers', async ({ page }) => {
  await page.route('**/search-index*', (r) => r.abort());
  await page.goto('/quran');
  await page.getByRole('searchbox').fill('الله نور السماوات');
  await expect(page.getByText('تعذر تحميل المحتوى')).toBeVisible();
  const retry = page.getByRole('button', { name: 'إعادة المحاولة' });
  await expect(retry).toBeVisible();
  await page.unroute('**/search-index*');
  await retry.click();
  await expect(page.locator('.ayah-hits a[href="/surah/24#ayah-35"]')).toBeVisible();
});
