import { test, expect } from '@playwright/test';

test.describe.configure({ timeout: 60_000 });

const CAIRO = { latitude: 30.0444, longitude: 31.2357 };

test('geo denial falls back to the city picker; a picked city renders the bearing', async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'geolocation', {
      configurable: true,
      value: {
        getCurrentPosition: (_ok: unknown, err: (e: unknown) => void) =>
          err({ code: 1, message: 'denied' }),
      },
    });
  });
  await page.goto('/qibla/');
  await page.locator('[data-qy="qb"][data-qy-ready="1"]').waitFor({ state: 'attached', timeout: 30_000 });
  await expect(page.locator('[data-qy="qb-picker"]')).toBeHidden();
  await page.locator('[data-qy="qb-geo"]').click();
  await expect(page.locator('[data-qy="qb-picker"]')).toBeVisible();
  await expect(page.locator('.qb-picker-msg')).toContainText('اختر مدينتك');
  await page.locator('[data-qy="qb-picker"] input[type="search"]').fill('القاهرة');
  await expect(page.locator('[data-qy="qb-picker"] .qb-cities li:visible')).toHaveCount(1);
  await page.locator('[data-qy="qb-picker"] .qb-cities li:visible button').click();
  await expect(page.locator('[data-qy="qb-result"]')).toBeVisible();
  await expect(page.locator('[data-qy="qb-deg"]')).toHaveText('١٣٦');
  await expect(page.locator('[data-qy="qb-place"]')).toHaveText('القاهرة');
  await expect(page.locator('[data-qy="qb-needle"]')).toHaveAttribute('transform', /^rotate\(136\./);
});

test('geolocation success renders the dial from the device position', async ({ page }) => {
  await page.addInitScript((coords) => {
    Object.defineProperty(navigator, 'geolocation', {
      configurable: true,
      value: {
        getCurrentPosition: (ok: (p: unknown) => void) =>
          ok({ coords: { ...coords, accuracy: 5 } }),
      },
    });
  }, CAIRO);
  await page.goto('/qibla/');
  await page.locator('[data-qy="qb"][data-qy-ready="1"]').waitFor({ state: 'attached', timeout: 30_000 });
  await page.locator('[data-qy="qb-geo"]').click();
  await expect(page.locator('[data-qy="qb-result"]')).toBeVisible();
  await expect(page.locator('[data-qy="qb-deg"]')).toHaveText('١٣٦');
  await expect(page.locator('[data-qy="qb-place"]')).toHaveText('موقعك الحالي');
  await expect(page.locator('[data-qy="qb-needle"]')).toHaveAttribute('transform', /^rotate\(136\./);
});

test('EN qibla page renders with EN labels', async ({ page }) => {
  await page.goto('/en/qibla/');
  await expect(page).toHaveTitle(/Qibla/);
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('[data-qy="qb-geo"]')).toHaveText('Use my location');
  await expect(page.locator('.qb-how')).toContainText('phone compass');
});

test('sitemap.xml carries the qibla route in both locales', async ({ request }) => {
  const body = await (await request.get('/sitemap.xml')).text();
  expect(body).toContain('<loc>https://quranyahdi.pages.dev/qibla/</loc>');
  expect(body).toContain('hreflang="en" href="https://quranyahdi.pages.dev/en/qibla/"');
});
