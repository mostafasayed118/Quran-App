import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };
import { LANDING } from '../../src/lib/landing-content';
import { t } from '../../src/lib/strings';

test('AR home carries locale head and the language switch', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  expect(await page.locator('head link[rel="alternate"][hreflang]').count()).toBeGreaterThanOrEqual(1);
  const switchLink = page.locator('header .lang-switch');
  await expect(switchLink).toHaveText('English');
  await expect(switchLink).toHaveAttribute('href', '/en/');
  await expect(switchLink).toHaveAttribute('rel', 'alternate');
});

test('EN home renders LTR chrome with the EN hero lead and 14 features', async ({ page }) => {
  await page.goto('/en/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('html')).toHaveAttribute('dir', 'ltr');
  await expect(page.locator('.hero-lead')).toHaveText(LANDING.en.hero.lead);
  await expect(page.locator('.feat-item')).toHaveCount(14);
  await expect(page.locator('.feat-item').first()).toContainText(LANDING.en.features[0].title);
  await expect(page.locator('.hero a[href="/en/quran"]')).toBeVisible();
  await expect(page.locator('.hero a[href="/en/about"]')).toBeVisible();
});

test('EN quran index shows the EN heading over 114 surah cards', async ({ page }) => {
  await page.goto('/en/quran');
  await expect(page.locator('h1.page-title')).toHaveText(t('en', 'surahIndexTitle'));
  await expect(page.locator('.surah-list a')).toHaveCount(114);
  expect(await page.locator('.surah-list a[href^="/en/surah/"]').count()).toBeGreaterThan(0);
});

test('EN reciters page resolves the loading state into EN content', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.goto('/en/reciters');
  await expect(page.locator('h1.page-title')).toHaveText(t('en', 'navReciters'));
  const featured = page.locator('#reciters-featured');
  await expect(featured).toBeVisible();
  await expect(page.locator('#reciters-status')).toBeHidden();
  const first = featured.locator('[data-reciter-row]').first();
  await expect(first.locator('.reciter-name')).toBeVisible();
  await first.locator('[data-reciter-toggle]').click();
  await expect(first.locator('[data-surah-row] [data-surah-download]').first()).toHaveText(t('en', 'recitersDownload'));
});

test('EN about page renders the EN mission copy', async ({ page }) => {
  await page.goto('/en/about');
  await expect(page.locator('.about .page-title')).toHaveText(t('en', 'navAbout'));
  await expect(page.locator('.about-story p').first()).toHaveText(LANDING.en.about.story[0]);
});
