import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test.beforeEach(async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
});

test('verses layout: one tab stop per ayah, Enter opens actions, Escape returns', async ({ page }) => {
  await page.goto('/surah/1/');
  const ayahs = page.locator('.ayah');
  const first = ayahs.first();
  await expect(first).toHaveAttribute('tabindex', '0');
  for (const action of ['copy', 'share', 'bookmark', 'listen']) {
    await expect(first.locator(`[data-ayah-action="${action}"]`)).toHaveAttribute('tabindex', '-1');
  }

  await first.focus();
  await expect(first).toHaveClass(/selected/);

  await page.keyboard.press('Enter');
  await expect(first.locator('[data-ayah-action="copy"]')).toBeFocused();

  await page.keyboard.press('Escape');
  await expect(first).toBeFocused();

  await page.keyboard.press('Tab');
  await expect(ayahs.nth(1)).toBeFocused();
});

test('pages layout: Enter opens the focused ayah actions', async ({ page }) => {
  await page.goto('/surah/1/');
  await page.locator('[data-qy-layout="pages"]').click();
  const shownPage = page.locator('.mushaf-page:not([hidden])');
  await expect(shownPage).toHaveCount(1);

  const ayah = shownPage.locator('.ayah').first();
  await ayah.focus();
  await ayah.press('Enter');
  await expect(ayah.locator('[data-ayah-action="copy"]')).toBeFocused();
});
