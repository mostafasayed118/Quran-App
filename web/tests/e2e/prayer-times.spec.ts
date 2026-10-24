import { test, expect } from '@playwright/test';

test.describe.configure({ timeout: 60_000 });

const daysIn = (y: number, m: number): number => new Date(y, m, 0).getDate();

test('cities index lists all 156 cities and filters instantly', async ({ page }) => {
  await page.goto('/prayer-times/');
  await page
    .locator('[data-qy="pt-cities"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  await expect(page.locator('.city-list a')).toHaveCount(156);
  await expect(async () => {
    await page.getByRole('searchbox').fill('الإسكندرية');
    await expect(page.locator('.city-list li:visible')).toHaveCount(1);
  }).toPass({ timeout: 10_000 });
  await expect(page.locator('.city-list li:visible a')).toHaveAttribute(
    'href',
    '/prayer-times/eg-alexandria/',
  );
});

test('city page SSRs the current month with today highlighted', async ({ page }) => {
  await page.goto('/prayer-times/eg-cairo/');
  await page
    .locator('[data-qy="pt-city"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  const now = new Date();
  const inRange = now.getFullYear() >= 2026 && now.getFullYear() <= 2027;
  const expectedValue = inRange ? `${now.getFullYear()}-${now.getMonth() + 1}` : '2026-1';
  await expect(page.locator('[data-qy="pt-month"]')).toHaveValue(expectedValue);
  const [vy, vm] = expectedValue.split('-').map(Number);
  const rows = page.locator('[data-qy="pt-table"] tbody tr');
  await expect(rows).toHaveCount(daysIn(vy, vm));
  await expect(rows.first()).toHaveAttribute('data-day', '1');
  if (inRange) {
    await expect(page.locator('[data-today="1"]')).toHaveCount(1);
    await expect(page.locator('[data-today="1"]')).toHaveAttribute(
      'data-day',
      String(now.getDate()),
    );
  } else {
    await expect(page.locator('[data-today="1"]')).toHaveCount(0);
  }
});

test('month switch re-renders the table and imsakiah toggle swaps the layout', async ({ page }) => {
  await page.goto('/prayer-times/eg-cairo/');
  await page
    .locator('[data-qy="pt-city"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  const now = new Date();
  const target = now.getFullYear() === 2027 && now.getMonth() === 11 ? '2026-1' : '2027-12';
  await page.locator('[data-qy="pt-month"]').selectOption(target);
  const [ty, tm] = target.split('-').map(Number);
  const rows = page.locator('[data-qy="pt-table"] tbody tr');
  await expect(rows).toHaveCount(daysIn(ty, tm));
  await expect(rows.last()).toHaveAttribute('data-day', String(daysIn(ty, tm)));
  const isTargetCurrent = now.getFullYear() === ty && now.getMonth() + 1 === tm;
  await expect(page.locator('[data-today="1"]')).toHaveCount(isTargetCurrent ? 1 : 0);

  const toggle = page.locator('[data-qy="pt-view-toggle"]');
  await expect(toggle).toHaveAttribute('aria-pressed', 'false');
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('.pt-table-wrap')).toHaveAttribute('data-view', 'imsakiah');
  await expect(
    page.locator('[data-view="imsakiah"] th[data-col="maghrib"] .lbl-imsakiah'),
  ).toBeVisible();
  await expect(
    page.locator('[data-view="imsakiah"] th[data-col="maghrib"] .lbl-times'),
  ).toBeHidden();
  await expect(page.locator('[data-view="imsakiah"] th[data-col="sunrise"]')).toBeHidden();
  await expect(page.locator('[data-view="imsakiah"] td[data-col="isha"]').first()).toBeHidden();

  await toggle.click();
  await expect(page.locator('.pt-table-wrap')).toHaveAttribute('data-view', 'times');
  await expect(page.locator('th[data-col="sunrise"]')).toBeVisible();
  await expect(page.locator('th[data-col="maghrib"] .lbl-times')).toBeVisible();
});

test('EN city page renders LTR chrome with EN labels, title and the AR lang switch', async ({
  page,
}) => {
  await page.goto('/en/prayer-times/eg-cairo/');
  await expect(page).toHaveTitle(/Prayer times in Cairo/);
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('[data-qy="pt-table"] thead')).toContainText('Fajr');
  await expect(page.locator('link[rel="alternate"][hreflang="ar"]')).toHaveAttribute(
    'href',
    /\/prayer-times\/eg-cairo\/$/,
  );
  await expect(page.locator('header nav a[href="/en/prayer-times/"]')).toHaveCount(1);
  await expect(page.locator('header nav a[href="/prayer-times/"]')).toHaveCount(0);
});

test('EN cities index works with the EN filter', async ({ page }) => {
  await page.goto('/en/prayer-times/');
  await expect(page).toHaveTitle(/Prayer Times/);
  await page
    .locator('[data-qy="pt-cities"][data-qy-ready="1"]')
    .waitFor({ state: 'attached', timeout: 30_000 });
  await expect(page.locator('.city-list a')).toHaveCount(156);
  await expect(async () => {
    await page.getByRole('searchbox').fill('Alexandria');
    await expect(page.locator('.city-list li:visible')).toHaveCount(1);
  }).toPass({ timeout: 10_000 });
});

test('sitemap.xml carries the prayer-times routes in both locales', async ({ request }) => {
  const res = await request.get('/sitemap.xml');
  const body = await res.text();
  expect(body).toContain('/prayer-times/eg-cairo/');
  expect(body).toContain('/en/prayer-times/eg-cairo/');
});
