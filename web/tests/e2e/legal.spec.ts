import { test, expect } from '@playwright/test';
import { t } from '../../src/lib/strings';

test('privacy page renders the repo PRIVACY.md — honesty summary and permissions table', async ({ page }) => {
  await page.goto('/privacy');
  await expect(page).toHaveTitle(`${t('ar', 'footerPrivacy')} — ${t('ar', 'appName')}`);
  const legal = page.locator('.legal');
  await expect(legal).toContainText('سياسة الخصوصية');
  await expect(legal.locator('blockquote').filter({ hasText: 'لا نجمع أي بيانات' })).toBeVisible();
  const table = legal.locator('table').first();
  await expect(table).toBeVisible();
  expect(await table.locator('tr').count()).toBeGreaterThanOrEqual(4);
});
