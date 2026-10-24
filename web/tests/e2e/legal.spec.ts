import { test, expect } from '@playwright/test';
import { t } from '../../src/lib/strings';

test('privacy page renders the repo PRIVACY.md — honesty summary and permissions table', async ({
  page,
}) => {
  await page.goto('/privacy');
  await expect(page).toHaveTitle(`${t('ar', 'footerPrivacy')} — ${t('ar', 'appName')}`);
  const legal = page.locator('.legal');
  await expect(legal).toContainText('سياسة الخصوصية');
  await expect(legal.locator('blockquote').filter({ hasText: 'لا نجمع أي بيانات' })).toBeVisible();
  const table = legal.locator('table').first();
  await expect(table).toBeVisible();
  expect(await table.locator('tr').count()).toBeGreaterThanOrEqual(4);
});

test('en privacy page renders PRIVACY.en.md — lang/dir, honesty summary and permissions table', async ({
  page,
}) => {
  await page.goto('/en/privacy');
  await expect(page).toHaveTitle(`${t('en', 'footerPrivacy')} — ${t('en', 'appName')}`);
  const html = page.locator('html');
  await expect(html).toHaveAttribute('lang', 'en');
  await expect(html).toHaveAttribute('dir', 'ltr');
  const legal = page.locator('.legal');
  await expect(legal.locator('h1')).toHaveText('Privacy Policy — Quran Yahdi');
  await expect(
    legal.locator('blockquote').filter({ hasText: 'We collect no data about you. At all.' }),
  ).toBeVisible();
  const table = legal.locator('table').first();
  await expect(table).toBeVisible();
  expect(await table.locator('tr').count()).toBeGreaterThanOrEqual(4);
});

test('AR /privacy is Arabic-only (trimmed)', async ({ page }) => {
  await page.goto('/privacy/');
  const legal = page.locator('.legal');
  expect(await page.locator('.legal #en-policy').count()).toBe(0);
  await expect(legal).not.toContainText('Privacy Policy');
  await expect(legal).not.toContainText('We collect no data');
  await expect(legal).toContainText('لا نجمع أي بيانات');
  const table = legal.locator('table').first();
  await expect(table).toBeVisible();
  expect(await table.locator('tr').count()).toBeGreaterThanOrEqual(4);
});
