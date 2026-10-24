import { test, expect } from '@playwright/test';
import surahsData from '../../src/data/surahs.json' with { type: 'json' };
import { META_DESCRIPTIONS, arReaderDescription } from '../../src/lib/landing-content';

test('AR pages carry localized meta descriptions', async ({ page }) => {
  const surah2 = (
    surahsData as { surahs: ReadonlyArray<{ id: number; nameAr: string }> }
  ).surahs.find((s) => s.id === 2);
  expect(surah2?.nameAr).toBe('البقرة');
  const meta = page.locator('meta[name="description"]');
  await page.goto('/quran');
  await expect(meta).toHaveAttribute('content', META_DESCRIPTIONS.ar.quran);
  await page.goto('/reciters');
  await expect(meta).toHaveAttribute('content', META_DESCRIPTIONS.ar.reciters);
  await page.goto('/surah/2');
  await expect(meta).toHaveAttribute('content', arReaderDescription(2, 'البقرة'));
  await expect(page.locator('meta[property="og:image"]')).toHaveAttribute(
    'content',
    /\/og\/surah\/2\.png$/,
  );
  await page.goto('/privacy');
  await expect(meta).toHaveAttribute('content', META_DESCRIPTIONS.ar.privacy);
});
