import { test, expect } from '@playwright/test';

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
