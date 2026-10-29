import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

async function expectMinHeight(
  page: import('@playwright/test').Page,
  selector: string,
): Promise<void> {
  const heights = await page
    .locator(selector)
    .evaluateAll((els) => els.map((el) => el.getBoundingClientRect().height));
  expect(heights.length, `${selector} present`).toBeGreaterThan(0);
  for (const h of heights) expect(h, selector).toBeGreaterThanOrEqual(44);
}

test.describe('coarse-pointer targets are at least 44px at 360', () => {
  test.use({ viewport: { width: 360, height: 800 }, hasTouch: true });

  test('header, chrome and hero controls', async ({ page }) => {
    await page.goto('/');
    for (const sel of [
      'header .brand',
      'header nav a',
      'header .lang-switch',
      'header .theme-toggle',
      '.hero__actions .heritage__btn',
      '.site-footer a',
    ]) {
      await expectMinHeight(page, sel);
    }
  });

  test('ayah actions, reader toolbar and reciter controls', async ({ page }) => {
    await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
    await page.goto('/surah/2/');
    for (const sel of [
      '.reader-controls .rc-btn',
      '.ayah-actions button',
      '[data-qy="reader-play"]',
      '.reader-nav a',
    ]) {
      await expectMinHeight(page, sel);
    }
    await page.goto('/reciters/');
    await page.locator('[data-reciter-row]').first().locator('[data-reciter-toggle]').click();
    for (const sel of ['[data-reciter-play]', '[data-surah-download]']) {
      await expectMinHeight(page, sel);
    }
  });
});

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
    await expect(page.locator('header nav a[aria-current="page"]')).toHaveAttribute(
      'href',
      '/quran/',
    );
    await page.goto('/en/reciters/');
    await expect(page.locator('header nav a[aria-current="page"]')).toHaveAttribute(
      'href',
      '/en/reciters/',
    );
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
  // sizes (px-derived sizes are intentionally unaffected). Header, footer and the document
  // must fit: the compact rules are viewport-based, so they stay active under the override.
  test('header and footer fit at 200% root font size on a 360px viewport', async ({ page }) => {
    await page.goto('/');
    await page.addStyleTag({ content: 'html { font-size: 200% !important; }' });
    const header = page.locator('header.site-header');
    const headerFit = await header.evaluate((el) => el.scrollWidth - el.clientWidth);
    expect(headerFit).toBeLessThanOrEqual(0);
    const footer = page.locator('footer.site-footer');
    const footerFit = await footer.evaluate((el) => el.scrollWidth - el.clientWidth);
    expect(footerFit).toBeLessThanOrEqual(0);
    const docOverflow = await page.evaluate(
      () => document.documentElement.scrollWidth - window.innerWidth,
    );
    expect(docOverflow).toBeLessThanOrEqual(0);
  });
});
