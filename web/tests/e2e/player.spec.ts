import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import reciters from '../fixtures/reciters-2.json' with { type: 'json' };

test('player: play from reciters page persists across SPA navigation', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/reciters/');
  await page.locator('[data-reciter-play]').first().click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  const seekBox = await page.locator('[data-qy="seek"]').boundingBox();
  expect(seekBox && seekBox.height).toBeGreaterThanOrEqual(44);
  await expect(bar.locator('[data-qy="title"]')).not.toBeEmpty();
  // Persistence is a CLIENT-ROUTER behavior: navigate via an in-app link, never page.goto (that reloads).
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();
  await expect(page.locator('[data-qy="toggle"]')).toHaveText('⏸');
  // Second SPA hop: quran index -> surah reader; the persisted player must survive again.
  await page.locator('.surah-list a[href="/surah/1"]').click();
  await page.waitForURL('**/surah/1**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();
  await expect(page.locator('[data-qy="toggle"]')).toHaveText('⏸');
});

test('player: close sticks while a track plays until a fresh play', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/surah/1/');
  const bar = page.locator('[data-qy="bar"]');
  await page.locator('[data-qy="reader-play"]').click();
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="toggle"]')).toHaveText('⏸');
  await bar.locator('[data-qy="close"]').click();
  await expect(bar).toBeHidden();
  await page.waitForTimeout(1500); // timeupdate emits ~4x/s must not re-show the bar
  await expect(bar).toBeHidden();
  await page.locator('[data-qy="reader-play"]').click();
  await expect(bar).toBeVisible();
});

test('player: audio error shows the localized message and toggle retries', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/surah/1/');
  const bar = page.locator('[data-qy="bar"]');
  const toggle = bar.locator('[data-qy="toggle"]');
  await page.locator('[data-qy="reader-play"]').click();
  await expect(bar).toBeVisible();
  await expect(toggle).toHaveText('⏸');
  // Settle into a real pause first, so the injected error lands on a paused element
  // (that is the state in which ▶ is the retry affordance).
  await toggle.click();
  await expect(toggle).toHaveText('▶');
  // Fault injection: a synthetic media error drives the exact listener the player
  // lib uses for real failures (player.ts error -> status 'error').
  await page.evaluate(() => {
    const el = document.getElementById('qy-audio');
    if (el) el.dispatchEvent(new Event('error'));
  });
  await expect(bar.locator('[data-qy="time"]')).toHaveText('تعذّر التشغيل');
  await expect(toggle).toHaveText('▶');
  await toggle.click(); // retry
  await expect(toggle).toHaveText('⏸');
  await expect(bar.locator('[data-qy="time"]')).not.toHaveText('تعذّر التشغيل');
});

test('player: seek slider is keyboard operable', async ({ page }) => {
  const wav = fs.readFileSync('tests/fixtures/silent.wav');
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  // Range-aware route: a plain 200 body is not seekable in Chromium (seekable collapses
  // to [0,0] and every seek clamps to 0), which would nullify the feature under test.
  // The real CDN serves byte ranges, so mirror that here.
  await page.route('**/cdn.mp3quran.net/**', async (route) => {
    const range = route.request().headers()['range'];
    if (range) {
      const m = /bytes=(\d+)-(\d*)/.exec(range);
      const start = m ? Number(m[1]) : 0;
      const end = m && m[2] ? Number(m[2]) : wav.length - 1;
      await route.fulfill({ status: 206, headers: { 'Content-Type': 'audio/wav', 'Accept-Ranges': 'bytes', 'Content-Range': `bytes ${start}-${end}/${wav.length}`, 'Content-Length': String(end - start + 1) }, body: wav.subarray(start, end + 1) });
    } else {
      await route.fulfill({ status: 200, headers: { 'Content-Type': 'audio/wav', 'Accept-Ranges': 'bytes', 'Content-Length': String(wav.length) }, body: wav });
    }
  });
  await page.goto('/surah/1/');
  const bar = page.locator('[data-qy="bar"]');
  const seek = bar.locator('[data-qy="seek"]');
  await page.locator('[data-qy="reader-play"]').click();
  await expect(bar).toBeVisible();
  await expect.poll(() => page.evaluate(() => (document.getElementById('qy-audio') as HTMLAudioElement).duration)).toBeGreaterThan(0);
  // Freeze playback first: with the 1s fixture, natural time drift would move
  // aria-valuenow on its own and fake a pass for the keypress assertion.
  await page.evaluate(() => { const el = document.getElementById('qy-audio') as HTMLAudioElement | null; if (el) el.pause(); });
  // Park the position at ~30% through the real click-to-seek path.
  const box = await seek.boundingBox();
  if (!box) throw new Error('seek slider has no box');
  await seek.click({ position: { x: Math.floor(box.width * 0.3), y: Math.floor(box.height / 2) } });
  const readPct = async () => Number(await seek.getAttribute('aria-valuenow'));
  await expect.poll(readPct).toBeGreaterThanOrEqual(20);
  await expect.poll(readPct).toBeLessThanOrEqual(40);
  await seek.focus();
  await expect(seek).toBeFocused();
  const before = await readPct();
  await page.keyboard.press('ArrowRight');
  await expect.poll(readPct).toBeGreaterThanOrEqual(before + 3);
});
