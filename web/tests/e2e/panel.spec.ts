import { test, expect } from '@playwright/test';
import translationFixture from '../fixtures/translation-1.json' with { type: 'json' };
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test.beforeEach(async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
});

test('content panel: curated packs render notes, switch, and persist across reload', async ({
  page,
}) => {
  await page.route('**/cdn.jsdelivr.net/gh/fawazahmed0/**', (r) =>
    r.fulfill({ json: translationFixture }),
  );
  await page.goto('/surah/1/');

  const panel = page.locator('#qy-content-panel');
  const toggle = page.locator('[data-qy="panel-toggle"]');
  await expect(panel).toBeHidden();
  await toggle.click();
  await expect(panel).toBeVisible();

  const pick = page.locator('[data-qy="content-pick"]');
  await pick.selectOption({ label: 'المختصر في التفسير - سِراج' });
  const notes = page.locator('.ayah-note');
  await expect(notes).toHaveCount(7);
  const texts = await notes.allTextContents();
  for (const text of texts) expect(text.trim().length).toBeGreaterThan(0);
  await expect(page.locator('.ayah[data-n="1"] .ayah-note[data-ayah="1"]')).toHaveText(
    translationFixture.chapter[0].text,
  );
  await expect(page.locator('.panel-source')).toContainText('QuranEnc.com');

  await pick.selectOption({ label: 'ترجمة بيكثال الإنجليزية' });
  await expect(notes).toHaveCount(7);
  await expect(page.locator('.ayah[data-n="1"] .ayah-note[data-ayah="1"]')).toHaveText(
    translationFixture.chapter[0].text,
  );
  await expect(page.locator('.panel-source')).toContainText('fawazahmed0/quran-api');
  await expect(page.locator('.panel-source')).toContainText('public domain');
  const stored = await page.evaluate(() => localStorage.getItem('qy:content'));
  expect(stored).toBe(JSON.stringify({ kind: 'translation', id: 'eng-mohammedmarmadu' }));

  await page.reload();
  await expect(panel).toBeHidden();
  await toggle.click();
  await expect(pick).toHaveValue('translation:eng-mohammedmarmadu');
  await expect(notes).toHaveCount(7);
});

test('content panel: pack failure shows error banner; retry after recovery reaches notes', async ({
  page,
}) => {
  await page.route('**/cdn.jsdelivr.net/gh/fawazahmed0/**', (r) => r.fulfill({ status: 500 }));
  await page.goto('/surah/1/');

  await page.locator('[data-qy="panel-toggle"]').click();
  await page
    .locator('[data-qy="content-pick"]')
    .selectOption({ label: 'المختصر في التفسير - سِراج' });
  await expect(page.locator('[data-qy="panel-error"]')).toBeVisible();
  await expect(page.locator('[data-qy="panel-retry"]')).toBeVisible();
  await expect(page.locator('.ayah-note')).toHaveCount(0);

  await page.unroute('**/cdn.jsdelivr.net/gh/fawazahmed0/**');
  await page.route('**/cdn.jsdelivr.net/gh/fawazahmed0/**', (r) =>
    r.fulfill({ json: translationFixture }),
  );
  await page.locator('[data-qy="panel-retry"]').click();
  await expect(page.locator('.ayah-note')).toHaveCount(7);
});
