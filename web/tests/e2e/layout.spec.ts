import { test, expect } from '@playwright/test';

test.describe('chrome a11y', () => {
  test('skip link is the first focusable and targets #main', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    const skip = page.locator('.skip-link');
    await expect(skip).toBeFocused();
    await expect(skip).toHaveAttribute('href', '#main');
    await page.keyboard.press('Enter');
    await expect(page.locator('main#main')).toBeFocused();
  });

  test('active nav link carries aria-current in both locales', async ({ page }) => {
    await page.goto('/quran/');
    await expect(page.locator('header nav a[aria-current="page"]')).toHaveAttribute('href', '/quran/');
    await page.goto('/en/reciters/');
    await expect(page.locator('header nav a[aria-current="page"]')).toHaveAttribute('href', '/en/reciters/');
    await page.goto('/en/');
    await expect(page.locator('header nav a[aria-current="page"]')).toHaveCount(0);
  });
});

test.describe('404 locale from the /en prefix', () => {
  test('/en/no-such flips to the EN block with EN links', async ({ page }) => {
    await page.goto('/en/no-such');
    await expect(page.locator('html')).toHaveAttribute('lang', 'en');
    await expect(page.locator('html')).toHaveAttribute('dir', 'ltr');
    const en = page.locator('[data-qy="not-found-en"]');
    await expect(en).toBeVisible();
    await expect(en.locator('h1')).toHaveText('Page not found');
    await expect(en.locator('a[href="/en/quran/"]')).toBeVisible();
    await expect(en.locator('a[href="/en/"]')).toBeVisible();
    await expect(page.locator('[data-qy="not-found"]')).toBeHidden();
  });

  test('/no-such keeps the AR default', async ({ page }) => {
    await page.goto('/no-such');
    await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
    const ar = page.locator('[data-qy="not-found"]');
    await expect(ar).toBeVisible();
    await expect(ar.locator('h1')).toHaveText('الصفحة غير موجودة');
    await expect(page.locator('[data-qy="not-found-en"]')).toBeHidden();
  });
});

test.describe('no horizontal overflow at 360px', () => {
  test.use({ viewport: { width: 360, height: 800 } });

  for (const path of ['/', '/en/', '/surah/2/', '/en/surah/2/']) {
    test(`document and header fit — ${path}`, async ({ page }) => {
      await page.goto(path);
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - window.innerWidth,
      );
      expect(overflow).toBeLessThanOrEqual(0);
      const box = await page.locator('header .theme-toggle').boundingBox();
      expect(box).not.toBeNull();
      if (box) {
        expect(box.x).toBeGreaterThanOrEqual(0);
        expect(box.x + box.width).toBeLessThanOrEqual(360);
      }
    });
  }

  // Technique: a root font-size override approximates 200% text scaling for rem-derived
  // sizes (px-derived sizes are intentionally unaffected). The header must still fit:
  // the compact rules are viewport-based, so they stay active under the override.
  // Scope note: assertion is header-only — the site footer (outside this wave's header
  // scope) still overflows internally at 200% on a 360px viewport; disclosed in the report.
  test('header fits at 200% root font size on a 360px viewport', async ({ page }) => {
    await page.goto('/');
    await page.addStyleTag({ content: 'html { font-size: 200% !important; }' });
    const header = page.locator('header.site-header');
    const fit = await header.evaluate((el) => el.scrollWidth - el.clientWidth);
    expect(fit).toBeLessThanOrEqual(0);
  });
});
