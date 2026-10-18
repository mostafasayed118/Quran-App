import { test, expect } from '@playwright/test';

test('landing renders the hero with the provisional ayah and both CTAs', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle('قرآن يَهدي');
  await expect(page.locator('.hero-ayah')).toBeVisible();
  await expect(page.locator('.hero-ayah')).toContainText('إِنَّ هَذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ');
  await expect(page.locator('.hero-ref')).toContainText('الإسراء ٩');
  await expect(page.locator('.hero a[href="/quran"]')).toBeVisible();
  await expect(page.locator('.hero a[href="/about"]')).toBeVisible();
});

test('landing shows the features heading, exactly 14 feature rows and the promise', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.features h2')).toBeVisible();
  await expect(page.locator('.feat-item')).toHaveCount(14);
  await expect(page.locator('.promise-item').first()).toBeVisible();
  expect(await page.locator('.promise-item').count()).toBeGreaterThanOrEqual(3);
});

test('landing nav points to the quran index and reciters', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('header a[href="/quran"]')).toHaveCount(1);
  await expect(page.locator('header a[href="/reciters"]')).toHaveCount(1);
});

test('landing shows no resume card with empty storage', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('[data-qy="resume"]')).toHaveCount(0);
});

test('landing resume card links to the stored last-read ayah', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:last-read', '{"s":36,"a":5}');
  });
  await page.goto('/');
  const card = page.locator('[data-qy="resume"]');
  await expect(card).toHaveCount(1);
  await expect(card).toHaveAttribute('href', '/surah/36#ayah-5');
  await expect(card).toContainText('يس');
});

test('landing ignores a corrupt resume point', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:last-read', 'not-json');
  });
  await page.goto('/');
  await expect(page.locator('[data-qy="resume"]')).toHaveCount(0);
});

test('landing resume card appears on ClientRouter entry from another page', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:last-read', '{"s":36,"a":5}');
  });
  await page.goto('/quran');
  await page.locator('header .brand').click();
  await page.waitForURL((url) => url.pathname === '/');
  await expect(page.locator('.hero-ayah')).toBeVisible();
  await expect(page.locator('[data-qy="resume"]')).toHaveCount(1);
});

test('landing resume card survives a ClientRouter round-trip', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('qy:last-read', '{"s":36,"a":5}');
  });
  await page.goto('/');
  await expect(page.locator('[data-qy="resume"]')).toHaveCount(1);
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran**');
  await page.locator('header .brand').click();
  await page.waitForURL((url) => url.pathname === '/');
  await expect(page.locator('[data-qy="resume"]')).toHaveCount(1);
});

test('landing CTA section links GitHub Releases live and shows the Play badge as coming-soon', async ({ page }) => {
  await page.goto('/');
  const github = page.locator('.cta a.cta-github');
  await expect(github).toBeVisible();
  await expect(github).toHaveAttribute('href', 'https://github.com/mostafasayed118/Quran-App/releases/latest');
  const play = page.locator('.cta span.cta-play');
  await expect(play).toHaveCount(1);
  await expect(play).toHaveAttribute('aria-disabled', 'true');
  await expect(play).toHaveText('قريبًا على Google Play');
  await expect(page.locator('.cta a.cta-play, .cta button.cta-play')).toHaveCount(0);
});
