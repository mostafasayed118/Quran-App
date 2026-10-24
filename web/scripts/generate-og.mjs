// Per-surah Open Graph images: 114 x 1200x630 PNG, rendered with the already-installed Playwright browser.
// Run from web/: `node scripts/generate-og.mjs` (or `npm run og`).
import { mkdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const OUT_DIR = join(ROOT, 'public', 'og', 'surah');
const PER_FILE_LIMIT = 150 * 1024;
const TOTAL_LIMIT = 6 * 1024 * 1024;

// Day-mode tokens from src/styles/tokens.css (no invented colors).
const PAPER = '#F2ECDD'; // --bg-solid
const INK = '#232D28'; // --ink
const MUTED = 'rgba(35, 45, 40, 0.6)'; // --muted
const GOLD = '#C9A96A'; // --gold-line
const GOLD_INK = '#7E5C1D'; // --gold-ink
const FAINT = 'rgba(35, 45, 40, 0.45)';

const surahs = JSON.parse(readFileSync(join(ROOT, 'src', 'data', 'surahs.json'), 'utf8')).surahs;
const fontData = (file) =>
  `data:font/woff2;base64,${readFileSync(join(ROOT, 'public', 'fonts', file)).toString('base64')}`;

const regular = fontData('Cairo-Regular.woff2');
const bold = fontData('Cairo-Bold.woff2');

const nameSize = (name) => (name.length >= 9 ? 96 : name.length >= 7 ? 112 : 128);
const revelation = (type) => (type === 'madinah' ? 'مدنية' : 'مكية');

const html = (surah) => `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<style>
  @font-face { font-family: 'Cairo'; font-style: normal; font-weight: 400; src: url(${regular}) format('woff2'); }
  @font-face { font-family: 'Cairo'; font-style: normal; font-weight: 700; src: url(${bold}) format('woff2'); }
  html, body { margin: 0; padding: 0; overflow: hidden; }
  body {
    width: 1200px; height: 630px; background: ${PAPER}; color: ${INK};
    font-family: 'Cairo', sans-serif; -webkit-font-smoothing: antialiased;
  }
  .card { position: relative; width: 1200px; height: 630px; }
  .frame { position: absolute; inset: 22px; border: 1px solid ${GOLD}; }
  .kicker {
    position: absolute; top: 52px; left: 0; right: 0; text-align: center;
    font-weight: 700; font-size: 30px; line-height: 1.2; color: ${GOLD_INK};
  }
  .center {
    position: absolute; top: 50%; left: 0; right: 0; transform: translateY(-56%);
    text-align: center;
  }
  .name {
    font-weight: 700; font-size: ${nameSize(surah.nameAr)}px; line-height: 1.18; color: ${INK};
  }
  .latin { font-weight: 400; font-size: 34px; line-height: 1.4; color: ${MUTED}; margin-top: 10px; }
  .meta { font-weight: 400; font-size: 26px; line-height: 1.4; color: ${MUTED}; margin-top: 4px; }
  .domain {
    position: absolute; bottom: 52px; left: 0; right: 0; text-align: center;
    font-weight: 400; font-size: 20px; line-height: 1.2; color: ${FAINT};
    direction: ltr;
  }
</style>
</head>
<body>
  <div class="card">
    <div class="frame"></div>
    <div class="kicker">قرآن يَهدي</div>
    <div class="center">
      <div class="name">${surah.nameAr}</div>
      <div class="latin">Surah ${surah.id} — ${surah.nameEn}</div>
      <div class="meta">${revelation(surah.revelationType)} · ${surah.ayahCount} آية</div>
    </div>
    <div class="domain">quranyahdi.pages.dev</div>
  </div>
</body>
</html>`;

mkdirSync(OUT_DIR, { recursive: true });

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 1200, height: 630 },
  deviceScaleFactor: 1,
});
const page = await context.newPage();

const sizes = [];
for (const surah of surahs) {
  await page.setContent(html(surah), { waitUntil: 'load' });
  await page.evaluate(() => document.fonts.ready);
  const path = join(OUT_DIR, `${surah.id}.png`);
  await page.screenshot({ path, type: 'png' });
  const bytes = statSync(path).size;
  sizes.push({ file: `${surah.id}.png`, bytes });
}

await browser.close();

const total = sizes.reduce((sum, s) => sum + s.bytes, 0);
const min = sizes.reduce((a, b) => (b.bytes < a.bytes ? b : a));
const max = sizes.reduce((a, b) => (b.bytes > a.bytes ? b : a));
const avg = Math.round(total / sizes.length);

console.log('OG images generated');
console.log(`count: ${sizes.length}`);
console.log(`total: ${(total / 1024 / 1024).toFixed(2)} MB (${total} bytes)`);
console.log(`min: ${min.file} ${(min.bytes / 1024).toFixed(1)} KB`);
console.log(`avg: ${(avg / 1024).toFixed(1)} KB`);
console.log(`max: ${max.file} ${(max.bytes / 1024).toFixed(1)} KB`);

const oversized = sizes.filter((s) => s.bytes > PER_FILE_LIMIT);
if (oversized.length > 0) {
  console.error(`STOP: ${oversized.length} file(s) exceed ${PER_FILE_LIMIT / 1024} KB`);
  for (const s of oversized) console.error(`  ${s.file} ${(s.bytes / 1024).toFixed(1)} KB`);
  process.exit(1);
}
if (total > TOTAL_LIMIT) {
  console.error(`STOP: total ${(total / 1024 / 1024).toFixed(2)} MB exceeds 6 MB`);
  process.exit(1);
}
