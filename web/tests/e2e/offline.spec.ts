import { test, expect } from '@playwright/test';

// This is the one spec that needs the real service worker; the global config blocks it.
test.use({ serviceWorkers: 'allow' });

// The home's h1 is the ayah since the heritage redesign (2026-10-29); the old
// kicker moved to a paragraph. The marker only proves the page rendered offline.
const HOME_H1 = '﴿إِنَّ هَذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ﴾';
const OFFLINE_H1 = 'أنت غير متصل';

test('a visited home page still renders after going offline', async ({ page, context }) => {
  const response = await page.goto('/');
  expect(response?.ok()).toBe(true);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(HOME_H1);

  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    return true;
  });

  // A page loaded before the worker activates has no controller: one reload binds it.
  await page.reload();
  await expect
    .poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller)), {
      timeout: 15_000,
    })
    .toBe(true);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(HOME_H1);

  try {
    await context.setOffline(true);

    let navigationError: unknown = null;
    try {
      await page.reload({ waitUntil: 'domcontentloaded' });
    } catch (error) {
      navigationError = error;
    }
    expect(navigationError, 'the worker must answer the offline navigation').toBeNull();

    const heading = page.getByRole('heading', { level: 1 });
    await expect(heading).toBeVisible();
    expect([HOME_H1, OFFLINE_H1]).toContain((await heading.textContent())?.trim());
    await expect(page.locator('body')).not.toContainText('ERR_INTERNET_DISCONNECTED');
    expect(page.url()).not.toContain('chrome-error');
  } finally {
    await context.setOffline(false);
  }
});
