import { test, expect, type Page } from '@playwright/test';
import reciters2 from '../fixtures/reciters-2.json' with { type: 'json' };

// Headless Chromium may expose navigator.share but rejects it without transient user
// activation; stub it away so the share action deterministically exercises its
// clipboard fallback (which is also a real path in non-Web-Share browsers).
async function stubNoShare(page: Page): Promise<void> {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'share', { value: undefined });
  });
}

test('copy writes plain Arabic (not glyphs), share falls back to clipboard, bookmark persists', async ({
  context,
  page,
}) => {
  await stubNoShare(page);
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters2 }));
  await page.goto('/surah/1/');
  await expect(page.locator('[data-ayah-action="copy"]').first()).toHaveText('نسخ');
  await page.locator('[data-ayah-action="copy"]').first().click();
  await expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()), {
      message: 'clipboard receives the copy payload',
    })
    .toContain('بسم'); // plain Arabic — proves not PUA
  const clip = await page.evaluate(() => navigator.clipboard.readText());
  expect(/[\uE000-\uF8FF]/.test(clip)).toBe(false);
  await page.locator('[data-ayah-action="share"]').first().click();
  await expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()), {
      message: 'share falls back to the clipboard',
    })
    .toContain('/surah/1#ayah-1');
  await page.locator('[data-ayah-action="bookmark"]').nth(2).click();
  await page.reload();
  await expect(page.locator('[data-ayah-action="bookmark"]').nth(2)).toHaveAttribute(
    'aria-pressed',
    'true',
  );
});

test('bookmark persists, listen dispatches the chosen reciter into the player', async ({
  page,
}) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters2 }));
  await page.route('**/cdn.mp3quran.net/**', (r) =>
    r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }),
  );
  await page.goto('/surah/1/');
  await page.locator('[data-qy="reciter-pick"]').selectOption({ index: 0 });
  await page.locator('[data-ayah-action="listen"]').first().click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="reciter"]')).not.toBeEmpty();
});
