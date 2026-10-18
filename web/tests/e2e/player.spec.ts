import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test('player: play from reciters page persists across SPA navigation', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/reciters/');
  await page.locator('[data-reciter-play]').first().click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="title"]')).not.toBeEmpty();
  // Persistence is a CLIENT-ROUTER behavior: navigate via an in-app link, never page.goto (that reloads).
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();
  await expect(page.locator('[data-qy="toggle"]')).toHaveText('⏸');
  // Second SPA hop: quran index -> surah reader; the persisted player must survive again.
  await page.locator('.surah-list a[href="/surah/1"]').click();
  await page.waitForURL('**/surah/1**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();
  await expect(page.locator('[data-qy="toggle"]')).toHaveText('⏸');
});
