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

test('EN surah reader mirrors the AR reader with LTR chrome over RTL ayah text', async ({ page }) => {
  await page.goto('/en/surah/2');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('html')).toHaveAttribute('dir', 'ltr');
  await expect(page.locator('.ayah')).toHaveCount(286);
  // Surah display name stays Arabic script (app parity); the chrome around it is EN.
  await expect(page.locator('.reader-head h1')).toContainText('البقرة');
  await expect(page.locator('[data-qy="reader-play"]')).toHaveText(t('en', 'readerPlay'));
  await expect(page.locator('[data-qy="reciter-pick"]')).toHaveAttribute('aria-label', t('en', 'readerPickReciter'));
  // Per-ayah action chrome is EN too (AyahBlock locale plumbing).
  await expect(page.locator('[data-ayah-action="copy"]').first()).toHaveText('Copy');
  // The ayah line keeps its RTL base direction even though the page chrome is LTR.
  const textDir = await page.locator('.ayah-text').first().evaluate((el) => getComputedStyle(el).direction);
  expect(textDir).toBe('rtl');
});

test('EN surah reader: mini-player plays and survives an in-app navigation', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/en/surah/1');
  await expect(page.locator('.reader')).toBeVisible();
  const bar = page.locator('[data-qy="bar"]');
  await page.locator('[data-qy="reader-play"]').click();
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="title"]')).not.toBeEmpty();
  // Persistence is a CLIENT-ROUTER behavior: hop via an in-app link, never page.goto.
  await page.locator('header a[href="/en/quran"]').click();
  await page.waitForURL('**/en/quran**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();
});

test('EN index card resolves to the live EN reader route', async ({ page }) => {
  await page.goto('/en/quran');
  await page.locator('.surah-list a[href="/en/surah/1"]').click();
  await page.waitForURL('**/en/surah/1**');
  await expect(page.locator('.reader-head h1')).toContainText('الفاتحة');
  await expect(page.locator('.ayah').first()).toBeVisible();
});

test('sitemap.xml is served as XML with the EN alternates', async ({ request }) => {
  const res = await request.get('/sitemap.xml');
  expect(res.status()).toBe(200);
  expect(res.headers()['content-type']).toMatch(/application\/xml|text\/xml/);
  const body = await res.text();
  expect(body).toContain('/en/surah/114');
  expect(body).toContain('hreflang="en"');
});

test('EN home theme toggle flips to night with the EN label', async ({ page }) => {
  await page.goto('/en/');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'day');
  await page.locator('.theme-toggle').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'night');
  await expect(page.locator('.theme-toggle')).toHaveText(t('en', 'themeToDay'));
});

test('EN home resume card links to the stored last-read ayah', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:last-read', '{"s":36,"a":5}');
  });
  await page.goto('/en/');
  const card = page.locator('[data-qy="resume"]');
  await expect(card).toHaveCount(1);
  await expect(card).toBeVisible();
  await expect(card).toHaveAttribute('href', '/en/surah/36#ayah-5');
  await expect(card).toContainText(t('en', 'resumeTitle'));
});

test('language switch round-trips between the AR and EN quran index', async ({ page }) => {
  await page.goto('/quran');
  await page.locator('header .lang-switch').click();
  await page.waitForURL('**/en/quran**');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('html')).toHaveAttribute('dir', 'ltr');
  await page.locator('header .lang-switch').click();
  await page.waitForURL((url) => url.pathname.replace(/\/+$/, '') === '/quran');
  await expect(page.locator('html')).toHaveAttribute('lang', 'ar');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
});
