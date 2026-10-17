# Web P1 — Foundation Implementation Plan (قرآن يَهدي سايت)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up `web/` — a live, gated Astro site with the locked «المَصحف» design system, a data generator sourced from the app's own `quran.sqlite`, a 114-surah reader (text), the surah index, and a Cloudflare Pages deployment.

**Architecture:** Astro 7 static-first (`output: 'static'`) in `web/` inside the app repo. Quran data is generated **once** by a Dart tool (same drift pattern as `tools/build_quran_db.dart`) and committed under `web/src/data/` — the Cloudflare build needs only Node. No server runtime, no accounts, no cookies. Day/night theming via CSS custom properties + `data-theme`, preference in `localStorage`.

**Tech Stack:** Astro 7.x · `@astrojs/react` (islands) · Tailwind CSS 4 (via `@tailwindcss/vite`) · TypeScript (strict) · Vitest (unit) · Playwright (smoke, chromium) · Node 22+ (local: v24.15.0) · Python 3.14 (asset prep only) · Dart (generator only) · Cloudflare Pages (free).

**Spec:** `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` (read it — this plan implements its P1 row, §3.1–3.3, §3.9, §4 AR routes, §5, §6).

## Global Constraints

- **Free-only**: every dependency must be free/open-source; no paid services, no analytics, no cookies, no accounts (spec W1/W2).
- **Node ≥ 22.22** required by Astro 7 (local v24.15.0 OK). All commands below run from the **repo root** `E:\old_flutter\Quran-App-master` unless stated.
- **Do not touch app code** (`lib/`, `android/`, `test/`, `assets/` are read-only for this plan). Two untracked test files (`test/quran_core_quality_probe_test.dart`, `test/reader_error_retry_test.dart`) and ` M .vscode/settings.json` are **foreign/owner debris — never add, never commit**.
- **Commits**: conventional prefix + explicit pathspec, one commit per task (or per noted sub-commit). **NO PUSH.** Gates green (`npm run check && npm run test && npm run build` in `web/`) before every commit.
- **Colors**: only via tokens (`web/src/styles/tokens.css`). No raw hex in any component/style outside the token file. Day/night values are LOCKED in spec §3.9 (one refinement below: `--gold-ink` day = `#7E5C1D`, darkened from `#8A6520` to clear WCAG AA with margin — update the spec table line in Task 9).
- **Quran text is generated, never hand-edited.** AR is the default locale and RTL; EN strings ship in the dictionary now, EN routes come in P3.
- **Arabic UI rules**: no `letter-spacing` on Arabic text; ayah display line-height ≥ 2.0.
- **Search index, audio, translations, reciters = P2.** This plan's generator emits only `surahs.json` + `ayahs/*.json` (spec §3.3's `search-index.json` is added when P2 extends the generator).

---

### Task 1: Scaffold `web/` + gates + CI

**Files:**
- Create: `web/` (Astro project: `package.json`, `astro.config.mjs`, `tsconfig.json`, `src/pages/index.astro`, `public/`, `tests/`)
- Create: `.github/workflows/web.yml`
- Modify: nothing in the app.

**Interfaces:**
- Produces: npm scripts used by every later task — `dev`, `build`, `preview`, `check`, `test`, `test:e2e`, `gates`; Astro config with `site`, i18n `ar`(default)/`en`, react + tailwind wiring.

- [ ] **Step 0: Start gate (verbatim — report output)**

Run:
```bash
git rev-parse --short=7 HEAD
git status --porcelain
node --version
npm --version
```
Expected: HEAD `fc957c1` or a later docs-only commit; porcelain shows ONLY `M .vscode/settings.json` + the two foreign `?? test/*.dart` files (do not touch); Node `v22+`.

- [ ] **Step 1: Scaffold**

```bash
npm create astro@latest web -- --template minimal --typescript strict --no-git --install
cd web
npm i @astrojs/react react react-dom tailwindcss @tailwindcss/vite
npm i -D vitest @astrojs/check typescript @playwright/test
npx playwright install chromium
```
(If a create-astro flag differs, choose: template `minimal`, TypeScript `strict`, no git, install deps.)

- [ ] **Step 2: Wire configs**

`web/astro.config.mjs`:
```js
// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://quranyahdi.pages.dev',
  output: 'static',
  i18n: {
    defaultLocale: 'ar',
    locales: ['ar', 'en'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [react()],
  vite: { plugins: [tailwindcss()] },
});
```

Also ensure `web/tsconfig.json` (scaffold-created) includes (additive; keep scaffold defaults):
```json
{ "extends": "astro/tsconfigs/strict", "compilerOptions": { "resolveJsonModule": true } }
```

`web/package.json` scripts:
```json
{
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "check": "astro check",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "gates": "npm run check && npm run test && npm run build"
  }
}
```

`web/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config';
export default defineConfig({ test: { include: ['tests/unit/**/*.test.ts'] } });
```

`web/playwright.config.ts`:
```ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests/e2e',
  use: { baseURL: 'http://localhost:4321' },
  webServer: {
    command: 'npm run build && npm run preview -- --port 4321',
    port: 4321,
    reuseExistingServer: !process.env.CI,
  },
});
```

`web/src/pages/index.astro` — minimal placeholder (replaced in Task 6):
```astro
<html lang="ar" dir="rtl"><body><h1>قرآن يَهدي</h1></body></html>
```

`.github/workflows/web.yml`:
```yaml
name: web-gates
on:
  push:
    paths: ['web/**', 'tools/export_web_data.dart', '.github/workflows/web.yml']
  pull_request:
    paths: ['web/**', 'tools/export_web_data.dart']
jobs:
  gates:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: web } }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm, cache-dependency-path: web/package-lock.json }
      - run: npm ci
      - run: npm run check
      - run: npm run test
      - run: npm run build
```
(Playwright e2e runs locally in P1; CI e2e wiring is P2.)

- [ ] **Step 3: Verify scaffold gates**

```bash
npm run check
npm run build
```
Expected: both exit 0; `dist/index.html` contains `قرآن يَهدي`.

- [ ] **Step 4: Commit**

```bash
git add web .github/workflows/web.yml
git commit -m "feat(web): scaffold astro app with strict ts, gates and CI workflow"
```

---

### Task 2: i18n strings module (TDD)

**Files:**
- Create: `web/src/lib/strings.ts`
- Test: `web/tests/unit/strings.test.ts`

**Interfaces:**
- Produces: `type Locale = 'ar' | 'en'`; `defaultLocale`; `t(locale, key): string`; `stringKeys: readonly StringKey[]` (full parity AR/EN). Used by every layout/component.

- [ ] **Step 1: Write the failing test**

`web/tests/unit/strings.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { t, stringKeys, defaultLocale } from '../../src/lib/strings';

describe('strings', () => {
  it('defaults to Arabic', () => {
    expect(defaultLocale).toBe('ar');
  });
  it('has a non-empty value for every key in both locales', () => {
    for (const key of stringKeys) {
      expect(t('ar', key).trim().length, `ar:${key}`).toBeGreaterThan(0);
      expect(t('en', key).trim().length, `en:${key}`).toBeGreaterThan(0);
    }
  });
  it('ships the core chrome strings', () => {
    expect(t('ar', 'navQuran')).toBe('المصحف');
    expect(t('en', 'navQuran')).toBe('Quran');
    expect(t('ar', 'themeToNight')).toBe('الوضع الليلي');
    expect(t('en', 'themeToNight')).toBe('Night mode');
  });
});
```

- [ ] **Step 2: Run it — expect FAIL** (`Cannot find module '../../src/lib/strings'`)

```bash
npm run test
```

- [ ] **Step 3: Implement**

`web/src/lib/strings.ts`:
```ts
export type Locale = 'ar' | 'en';
export const defaultLocale: Locale = 'ar';

const dict = {
  ar: {
    appName: 'قرآن يَهدي',
    navQuran: 'المصحف',
    navReciters: 'التلاوات',
    navAbout: 'عن التطبيق',
    themeToNight: 'الوضع الليلي',
    themeToDay: 'الوضع النهاري',
    surahIndexTitle: 'المصحف',
    indexSearchPlaceholder: 'ابحث بالاسم أو الرقم…',
    noResults: 'لا نتائج',
    readerPrev: 'السورة السابقة',
    readerNext: 'السورة التالية',
    chipMeccan: 'مكية',
    chipMedinan: 'مدنية',
    footerPrivacy: 'سياسة الخصوصية',
    footerAbout: 'عن التطبيق',
    backToIndex: 'كل السور',
  },
  en: {
    appName: 'Quran Yahdi',
    navQuran: 'Quran',
    navReciters: 'Recitations',
    navAbout: 'About',
    themeToNight: 'Night mode',
    themeToDay: 'Day mode',
    surahIndexTitle: 'The Quran',
    indexSearchPlaceholder: 'Search by name or number…',
    noResults: 'No results',
    readerPrev: 'Previous surah',
    readerNext: 'Next surah',
    chipMeccan: 'Meccan',
    chipMedinan: 'Medinan',
    footerPrivacy: 'Privacy',
    footerAbout: 'About',
    backToIndex: 'All surahs',
  },
} as const;

export type StringKey = keyof (typeof dict)['ar'];
export const stringKeys = Object.keys(dict.ar) as StringKey[];

export function t(locale: Locale, key: StringKey): string {
  return dict[locale][key];
}
```

- [ ] **Step 4: Run tests — expect PASS** (`npm run test`)

- [ ] **Step 5: Commit**

```bash
git add web/src/lib/strings.ts web/tests/unit/strings.test.ts
git commit -m "feat(web): bilingual strings module with parity test"
```

---

### Task 3: Design tokens + fonts (TDD contrast gate)

**Files:**
- Create: `web/src/styles/tokens.css`, `web/src/styles/fonts.css`, `web/src/styles/global.css`
- Test: `web/tests/unit/contrast.test.ts`
- Create (binary): `web/public/fonts/HafsSmart_08.woff2`, `Cairo-Regular.woff2`, `Cairo-Bold.woff2`, `me_quran.woff2`, plus `web/public/fonts/Cairo-OFL.txt` (copied)

**Interfaces:**
- Produces: CSS custom properties `--bg-solid, --ink, --muted, --hairline, --frame, --frame2, --accent, --btn-bg, --btn-ink, --gold-line, --gold-ink, --surface` for `:root`/`[data-theme='day']` and `[data-theme='night']`; `@font-face` families `HafsSmart`, `Cairo`, `me_quran`.

- [ ] **Step 1: Write the failing test**

`web/tests/unit/contrast.test.ts` (parses the real token file, so tests fail until it exists and stays honest):
```ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16)) as [number, number, number];
}
function luminance(hex: string): number {
  const [r, g, b] = hexToRgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
function contrast(a: string, b: string): number {
  const [l1, l2] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (l1 + 0.05) / (l2 + 0.05);
}

const css = readFileSync(new URL('../../src/styles/tokens.css', import.meta.url), 'utf8');
function token(theme: 'day' | 'night', name: string): string {
  const block = theme === 'day'
    ? css.match(/\[data-theme=['"]day['"]\][^}]*}/)?.[0] ?? ''
    : css.match(/\[data-theme=['"]night['"]\][^}]*}/)?.[0] ?? '';
  const m = block.match(new RegExp(`${name}\\s*:\\s*(#[0-9a-fA-F]{6})`));
  if (!m) throw new Error(`token ${name} missing in ${theme}`);
  return m[1];
}

const AA = 4.5;
describe('WCAG AA contrast (token pairs, spec §3.9)', () => {
  it.each([
    ['day', '--ink', '--bg-solid'],
    ['day', '--gold-ink', '--bg-solid'],
    ['day', '--accent', '--bg-solid'],
    ['day', '--btn-ink', '--btn-bg'],
    ['night', '--ink', '--surface'],
    ['night', '--gold-ink', '--surface'],
    ['night', '--accent', '--surface'],
    ['night', '--btn-ink', '--btn-bg'],
  ] as const)('%s: %s on %s', (theme, fg, bg) => {
    expect(contrast(token(theme, fg), token(theme, bg))).toBeGreaterThanOrEqual(AA);
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (`token --bg-solid missing in day`)

```bash
npm run test
```

- [ ] **Step 3: Implement tokens + fonts + global styles**

`web/src/styles/tokens.css` (LOCKED values; day `--gold-ink` refined to `#7E5C1D` for AA margin):
```css
:root, [data-theme='day'] {
  --bg-solid: #F2ECDD;
  --ink: #232D28;
  --muted: rgba(35, 45, 40, 0.6);
  --hairline: rgba(35, 45, 40, 0.12);
  --frame: rgba(201, 169, 106, 0.85);
  --frame2: rgba(62, 107, 88, 0.30);
  --accent: #3E6B58;
  --btn-bg: #3E6B58;
  --btn-ink: #F7F3E8;
  --gold-line: #C9A96A;
  --gold-ink: #7E5C1D;
  --surface: #F2ECDD;
}
[data-theme='night'] {
  --bg-solid: #012A27;
  --ink: #F0E0C6;
  --muted: rgba(240, 224, 198, 0.55);
  --hairline: rgba(240, 224, 198, 0.13);
  --frame: rgba(201, 169, 106, 0.5);
  --frame2: rgba(201, 169, 106, 0.2);
  --accent: #E3A53E;
  --btn-bg: #E3A53E;
  --btn-ink: #161006;
  --gold-line: rgba(216, 179, 106, 0.6);
  --gold-ink: #D8B36A;
  --surface: #012A27;
}
body::before {
  content: '';
  position: fixed;
  inset: 0;
  z-index: -1;
  background: linear-gradient(180deg, #012E2B 0%, #012A27 45%, #012321 100%);
  opacity: 0;
  transition: opacity 0.5s ease;
}
[data-theme='night'] body::before { opacity: 1; }
@media (prefers-reduced-motion: reduce) {
  body::before { transition: none; }
}
```

`web/src/styles/fonts.css`:
```css
@font-face { font-family: 'HafsSmart'; src: url('/fonts/HafsSmart_08.woff2') format('woff2'); font-display: swap; }
@font-face { font-family: 'me_quran'; src: url('/fonts/me_quran.woff2') format('woff2'); font-display: swap; }
@font-face { font-family: 'Cairo'; src: url('/fonts/Cairo-Regular.woff2') format('woff2'); font-weight: 400; font-display: swap; }
@font-face { font-family: 'Cairo'; src: url('/fonts/Cairo-Bold.woff2') format('woff2'); font-weight: 700; font-display: swap; }
```

`web/src/styles/global.css` (base reset + reading styles; full body styles grow in Task 6):
```css
*, *::before, *::after { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg-solid);
  color: var(--ink);
  font-family: 'Cairo', system-ui, sans-serif;
  line-height: 1.7;
  transition: color 0.45s ease;
}
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
```

- [ ] **Step 4: Convert fonts (one-time, committed output)**

```bash
pip install fonttools brotli
fonttools ttLib.woff2 compress assets/fonts/HafsSmart_08.ttf -o web/public/fonts/HafsSmart_08.woff2
fonttools ttLib.woff2 compress assets/fonts/me_quran.ttf -o web/public/fonts/me_quran.woff2
fonttools ttLib.woff2 compress assets/fonts/Cairo-Regular.ttf -o web/public/fonts/Cairo-Regular.woff2
fonttools ttLib.woff2 compress assets/fonts/Cairo-Bold.ttf -o web/public/fonts/Cairo-Bold.woff2
copy assets\fonts\Cairo-OFL.txt web\public\fonts\Cairo-OFL.txt
```
Verify each `.woff2` exists and is 40–250KB (no subsetting of HafsSmart — Quran shaping). If `fonttools ttLib.woff2` is unavailable in this version, use `python -m fonttools.ttLib.woff2 compress <in> -o <out>`.

- [ ] **Step 5: Run tests + build — expect PASS**

```bash
npm run test
npm run build
```

- [ ] **Step 6: Commit**

```bash
git add web/src/styles web/public/fonts web/tests/unit/contrast.test.ts
git commit -m "feat(web): locked design tokens with AA contrast gate and woff2 fonts"
```

---

### Task 4: Brand assets (logo derivatives)

**Files:**
- Create: `web/src/assets/brand/logo-master.png` (copy of `E:\old_flutter\Quran-web\Dark Green Quran Logo.png`)
- Create: `web/scripts/prepare_brand_assets.py`
- Create (outputs): `web/public/logo-64.png`, `web/public/favicon-32.png`, `web/public/favicon-16.png`, `web/public/apple-touch-icon-180.png`, `web/public/og-base.png`
- Test: `web/tests/unit/assets.test.ts`

**Interfaces:**
- Produces: the five public asset paths above (used by BaseLayout Task 6).

- [ ] **Step 1: Copy master + write the failing test**

```bash
mkdir web\src\assets\brand
copy "E:\old_flutter\Quran-web\Dark Green Quran Logo.png" web\src\assets\brand\logo-master.png
```

`web/tests/unit/assets.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { statSync } from 'node:fs';

const files = ['logo-64.png', 'favicon-32.png', 'favicon-16.png', 'apple-touch-icon-180.png', 'og-base.png'];
describe('brand assets exist', () => {
  it.each(files)('public/%s', (f) => {
    const s = statSync(new URL(`../../public/${f}`, import.meta.url));
    expect(s.size).toBeGreaterThan(1000);
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
npm run test
```

- [ ] **Step 3: Implement the generator + run it**

`web/scripts/prepare_brand_assets.py`:
```python
"""Generates public brand assets from the master logo. Run from repo root: python web/scripts/prepare_brand_assets.py"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]          # repo root
master = Image.open(root / "web/src/assets/brand/logo-master.png").convert("RGBA")
pub = root / "web/public"

for size, name in [(64, "logo-64.png"), (180, "apple-touch-icon-180.png"),
                   (32, "favicon-32.png"), (16, "favicon-16.png")]:
    master.resize((size, size), Image.LANCZOS).save(pub / name)

og = Image.new("RGB", (1200, 630), (1, 42, 39))     # logo green #012A27
logo = master.resize((420, 420), Image.LANCZOS)
og.paste(logo, ((1200 - 420) // 2, (630 - 420) // 2), logo)
og.save(pub / "og-base.png")
print("brand assets written to web/public/")
```

```bash
pip install pillow
python web/scripts/prepare_brand_assets.py
```

- [ ] **Step 4: Run tests — expect PASS** (`npm run test`)

- [ ] **Step 5: Commit**

```bash
git add web/src/assets/brand/logo-master.png web/scripts/prepare_brand_assets.py web/public/logo-64.png web/public/favicon-32.png web/public/favicon-16.png web/public/apple-touch-icon-180.png web/public/og-base.png web/tests/unit/assets.test.ts
git commit -m "feat(web): brand assets generated from the master logo"
```

---

### Task 5: Data generator (Dart) + generated data + validation test

**Files:**
- Create: `tools/export_web_data.dart`
- Create (outputs, committed): `web/src/data/surahs.json`, `web/src/data/ayahs/1.json` … `114.json`
- Test: `web/tests/unit/data.test.ts`

**Interfaces:**
- Produces: `surahs.json` = `{ surahs: [{ id, nameAr, nameEn, revelationType, ayahCount, pagesStart, pagesEnd }] }`; `ayahs/<n>.json` = `{ surah, ayahs: [{ n, juz, page, u, i, sajda }] }` (`u` = Uthmani, `i` = Imlaei). All later reader/index tasks consume exactly this shape.

- [ ] **Step 1: Write the failing test**

`web/tests/unit/data.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import surahs from '../../src/data/surahs.json';

const load = (n: number) => import(`../../src/data/ayahs/${n}.json`).then((m) => m.default as {
  surah: number; ayahs: { n: number; juz: number; page: number; u: string; i: string; sajda: boolean }[];
});

describe('generated quran data', () => {
  it('has 114 surahs', () => expect(surahs.surahs).toHaveLength(114));
  it('totals 6236 ayahs', async () => {
    let total = 0;
    for (const s of surahs.surahs) total += (await load(s.id)).ayahs.length;
    expect(total).toBe(6236);
  });
  it('spot-checks: Fatiha 7 ayahs, Baqara 286, Kahf 110', () => {
    const byId = Object.fromEntries(surahs.surahs.map((s) => [s.id, s]));
    expect(byId[1].ayahCount).toBe(7);
    expect(byId[2].ayahCount).toBe(286);
    expect(byId[18].ayahCount).toBe(110);
  });
  it('spot-checks Ayat al-Kursi text (diacritic-tolerant)', async () => {
    const normalize = (s: string) =>
      s.replace(/[\u064B-\u0652\u0670\u0640]/g, '').replace(/[\u0671أإآ]/g, 'ا').replace(/ى/g, 'ي');
    const baqara = await load(2);
    const ayah = baqara.ayahs.find((a) => a.n === 255);
    expect(normalize(ayah?.u ?? '')).toContain('الكرسي');
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (`Cannot find module '../../src/data/surahs.json'`)

```bash
npm run test
```

- [ ] **Step 3: Implement the generator**

`tools/export_web_data.dart` (same drift pattern as the proven `tools/build_quran_db.dart`; run from repo root):
```dart
// Generates web/src/data from assets/db/quran.sqlite (the app's shipped DB).
// Run from repo root:  dart run tools/export_web_data.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:quran_yahdi/core/db/app_database.dart';

Future<void> main() async {
  final root = Directory.current.path;
  final db = AppDatabase(NativeDatabase(File('$root/assets/db/quran.sqlite')));

  final outDir = Directory('$root/web/src/data')..createSync(recursive: true);
  final ayahDir = Directory('${outDir.path}/ayahs')..createSync(recursive: true);

  final surahs = await (db.select(db.surahs)
        ..orderBy([(t) => OrderingTerm(expression: t.id)]))
      .get();
  if (surahs.length != 114) {
    stderr.writeln('expected 114 surahs, got ${surahs.length}');
    exitCode = 1;
    return;
  }

  var total = 0;
  final surahRows = <Map<String, Object?>>[];
  for (final s in surahs) {
    final ayahs = await (db.select(db.ayahs)
          ..where((t) => t.surahId.equals(s.id))
          ..orderBy([(t) => OrderingTerm(expression: t.numberInSurah)]))
        .get();
    if (ayahs.length != s.ayahCount) {
      stderr.writeln('surah ${s.id}: ${ayahs.length} ayahs != ${s.ayahCount}');
      exitCode = 1;
      return;
    }
    total += ayahs.length;
    surahRows.add({
      'id': s.id, 'nameAr': s.nameAr, 'nameEn': s.nameEn,
      'revelationType': s.revelationType, 'ayahCount': s.ayahCount,
      'pagesStart': s.pagesStart, 'pagesEnd': s.pagesEnd,
    });
    File('${ayahDir.path}/${s.id}.json').writeAsStringSync(jsonEncode({
      'surah': s.id,
      'ayahs': [
        for (final a in ayahs)
          {'n': a.numberInSurah, 'juz': a.juz, 'page': a.page,
           'u': a.textUthmani, 'i': a.textImlaei, 'sajda': a.sajda},
      ],
    }));
  }
  if (total != 6236) {
    stderr.writeln('expected 6236 ayahs, got $total');
    exitCode = 1;
    return;
  }
  File('${outDir.path}/surahs.json')
      .writeAsStringSync(jsonEncode({'surahs': surahRows}));
  await db.close();
  stdout.writeln('OK: wrote 114 surahs + $total ayahs to web/src/data');
}
```

- [ ] **Step 4: Run the generator, then the tests**

```bash
dart run tools/export_web_data.dart
npm run test --prefix web
```
Expected: `OK: wrote 114 surahs + 6236 ayahs`; vitest all green (this proves text parity with the app DB by construction).

- [ ] **Step 5: Commit**

```bash
git add tools/export_web_data.dart web/src/data web/tests/unit/data.test.ts
git commit -m "feat(web): quran data generator sourced from the app db + validation tests"
```

---

### Task 6: Base layout + theme system + chrome (Header/Footer/ThemeToggle)

**Files:**
- Create: `web/src/lib/theme.ts`, `web/src/components/ThemeToggle.tsx`, `web/src/layouts/BaseLayout.astro`, `web/src/components/Header.astro`, `web/src/components/Footer.astro`
- Modify: `web/src/pages/index.astro` (placeholder → real shell)
- Test: `web/tests/unit/theme.test.ts`, `web/tests/e2e/home.spec.ts`

**Interfaces:**
- Consumes: `t`, `Locale` (Task 2); tokens/fonts (Task 3); `logo-64.png` (Task 4).
- Produces: `Theme = 'day' | 'night'`; `THEME_KEY = 'qy:theme'`; `otherTheme(t)`; `readTheme(storage, prefersDark)`; `BaseLayout` props `{ title: string; description?: string; locale?: Locale; preloadFont?: boolean }` (all later pages wrap in it).

- [ ] **Step 1: Write the failing unit test**

`web/tests/unit/theme.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { otherTheme, readTheme, THEME_KEY } from '../../src/lib/theme';

describe('theme', () => {
  it('flips between day and night', () => {
    expect(otherTheme('day')).toBe('night');
    expect(otherTheme('night')).toBe('day');
  });
  it('reads a saved preference first', () => {
    expect(readTheme({ getItem: () => 'night' }, false)).toBe('night');
    expect(readTheme({ getItem: () => 'day' }, true)).toBe('day');
  });
  it('falls back to system preference', () => {
    expect(readTheme({ getItem: () => null }, true)).toBe('night');
    expect(readTheme(null, false)).toBe('day');
  });
  it('uses the namespaced key', () => expect(THEME_KEY).toBe('qy:theme'));
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
npm run test
```

- [ ] **Step 3: Implement lib + components + layout**

`web/src/lib/theme.ts`:
```ts
export type Theme = 'day' | 'night';
export const THEME_KEY = 'qy:theme';
export function otherTheme(t: Theme): Theme { return t === 'day' ? 'night' : 'day'; }
export function readTheme(
  storage: Pick<Storage, 'getItem'> | null,
  prefersDark: boolean,
): Theme {
  const saved = storage?.getItem(THEME_KEY);
  if (saved === 'day' || saved === 'night') return saved;
  return prefersDark ? 'night' : 'day';
}
```

`web/src/components/ThemeToggle.tsx`:
```tsx
import { useEffect, useState } from 'react';
import { otherTheme, readTheme, THEME_KEY, type Theme } from '../lib/theme';
import { t, type Locale } from '../lib/strings';

export default function ThemeToggle({ locale }: { locale: Locale }) {
  const [theme, setTheme] = useState<Theme>('day');
  useEffect(() => {
    setTheme(readTheme(localStorage, matchMedia('(prefers-color-scheme: dark)').matches));
  }, []);
  const label = theme === 'day' ? t(locale, 'themeToNight') : t(locale, 'themeToDay');
  return (
    <button
      class="theme-toggle"
      aria-label={label}
      onClick={() => {
        const next = otherTheme(theme);
        setTheme(next);
        document.documentElement.setAttribute('data-theme', next);
        try { localStorage.setItem(THEME_KEY, next); } catch { /* private mode */ }
      }}
    >
      {label}
    </button>
  );
}
```

`web/src/layouts/BaseLayout.astro`:
```astro
---
import '../styles/tokens.css';
import '../styles/fonts.css';
import '../styles/global.css';
import Header from '../components/Header.astro';
import Footer from '../components/Footer.astro';
import type { Locale } from '../lib/strings';

interface Props { title: string; description?: string; locale?: Locale; preloadFont?: boolean; }
const { title, description = 'قرآن يَهدي — اقرأ واستمع وتدبّر، مجاناً وبلا حسابات.', locale = 'ar', preloadFont = false } = Astro.props;
const dir = locale === 'ar' ? 'rtl' : 'ltr';
---
<!doctype html>
<html lang={locale} dir={dir} data-theme="day">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="icon" href="/favicon-32.png" sizes="32x32" />
    <link rel="apple-touch-icon" href="/apple-touch-icon-180.png" />
    {preloadFont && <link rel="preload" href="/fonts/HafsSmart_08.woff2" as="font" type="font/woff2" crossorigin />}
    <script is:inline>
      (function () {
        try {
          var saved = localStorage.getItem('qy:theme');
          var sys = matchMedia('(prefers-color-scheme: dark)').matches ? 'night' : 'day';
          document.documentElement.setAttribute('data-theme', saved || sys);
        } catch (e) { /* keep day */ }
      })();
    </script>
  </head>
  <body>
    <Header locale={locale} />
    <main><slot /></main>
    <Footer locale={locale} />
  </body>
</html>
```

`web/src/components/Header.astro`:
```astro
---
import ThemeToggle from './ThemeToggle.tsx';
import { t, type Locale } from '../lib/strings';
interface Props { locale?: Locale }
const { locale = 'ar' } = Astro.props;
---
<header class="site-header">
  <a class="brand" href="/">
    <img src="/logo-64.png" alt={t(locale, 'appName')} width="27" height="27" />
    <span>{t(locale, 'appName')}</span>
  </a>
  <nav>
    <a href="/quran">{t(locale, 'navQuran')}</a>
    <a href="/about">{t(locale, 'navAbout')}</a>
  </nav>
  <ThemeToggle locale={locale} client:load />
</header>
```
(`navReciters` link joins in P2.)

`web/src/components/Footer.astro`:
```astro
---
import { t, type Locale } from '../lib/strings';
interface Props { locale?: Locale }
const { locale = 'ar' } = Astro.props;
---
<footer class="site-footer">
  <a href="/privacy">{t(locale, 'footerPrivacy')}</a>
  <a href="/about">{t(locale, 'footerAbout')}</a>
</footer>
```

Add minimal styles to `global.css` (append): header/footer flex rows with `border-bottom: 1px solid var(--hairline)`, padded container `max-width: 1080px; margin-inline: auto; padding: 14px 20px`, brand `display:flex; gap:9px; color: var(--accent); font-weight:700`, nav links `color: var(--muted)`, `.theme-toggle { background: var(--btn-bg); color: var(--btn-ink); border: 0; border-radius: 999px; padding: 9px 18px; font-family: inherit; font-weight: 700; cursor: pointer; }`.

`web/src/pages/index.astro` (temporary shell until P3 landing):
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title="قرآن يَهدي">
  <section class="home-stub" style="text-align:center; padding: 60px 20px;">
    <h1>قرآن يَهدي</h1>
    <p><a href="/quran">المصحف</a></p>
  </section>
</BaseLayout>
```

- [ ] **Step 4: Write the failing e2e smoke**

`web/tests/e2e/home.spec.ts`:
```ts
import { test, expect } from '@playwright/test';

test('home renders RTL with chrome and toggles theme', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'day');
  await page.getByRole('button', { name: 'الوضع الليلي' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'night');
  await expect(page.getByRole('button', { name: 'الوضع النهاري' })).toBeVisible();
});
```

- [ ] **Step 5: Run unit + build + e2e — expect PASS**

```bash
npm run test
npm run check
npm run test:e2e
```

- [ ] **Step 6: Commit**

```bash
git add web/src/lib/theme.ts web/src/components web/src/layouts web/src/pages/index.astro web/tests/unit/theme.test.ts web/tests/e2e/home.spec.ts web/src/styles/global.css
git commit -m "feat(web): base layout, theme system with no-flash script, header and footer"
```

---

### Task 7: Surah index `/quran` (TDD filter)

**Files:**
- Create: `web/src/lib/surah-filter.ts`, `web/src/components/SurahIndexFilter.tsx`, `web/src/pages/quran.astro`
- Test: `web/tests/unit/surah-filter.test.ts`, `web/tests/e2e/index.spec.ts`

**Interfaces:**
- Consumes: `surahs.json` (Task 5), `t` (Task 2), `BaseLayout` (Task 6).
- Produces: `normalizeQuery(q: string): string`; `filterSurahs<T extends {id:number; nameAr:string; nameEn:string}>(list: T[], q: string): T[]` (ranking: exact id/name match first, then startsWith, then includes).

- [ ] **Step 1: Write the failing test**

`web/tests/unit/surah-filter.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { normalizeQuery, filterSurahs } from '../../src/lib/surah-filter';
import surahs from '../../src/data/surahs.json';

const list = surahs.surahs;

describe('normalizeQuery', () => {
  it('strips tashkeel and unifies hamza forms', () => {
    expect(normalizeQuery('الْكَهْف')).toBe('الكهف');
    expect(normalizeQuery('إسراء')).toBe('اسراء');
    expect(normalizeQuery('ٱلرَّحْمَٰنِ')).toBe('الرحمن');
  });
});

describe('filterSurahs', () => {
  it('empty query returns all', () => expect(filterSurahs(list, '')).toHaveLength(114));
  it('finds by number', () => expect(filterSurahs(list, '18')[0].id).toBe(18));
  it('finds by Arabic name with/without tashkeel', () => {
    expect(filterSurahs(list, 'الكهف')[0].id).toBe(18);
    expect(filterSurahs(list, 'الرحمن')[0].id).toBe(55);
  });
  it('finds by latin name', () => expect(filterSurahs(list, 'kahf')[0].id).toBe(18));
  it('exact name ranks before contains', () => {
    const ids = filterSurahs(list, 'النور').map((s) => s.id);
    expect(ids[0]).toBe(24);
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
npm run test
```

- [ ] **Step 3: Implement**

`web/src/lib/surah-filter.ts`:
```ts
export function normalizeQuery(q: string): string {
  return q
    .trim()
    .toLowerCase()
    .replace(/[\u064B-\u0652\u0670\u0640]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه');
}

export interface SurahLike { id: number; nameAr: string; nameEn: string }

export function filterSurahs<T extends SurahLike>(list: T[], q: string): T[] {
  const n = normalizeQuery(q);
  if (!n) return list;
  const asNum = /^\d+$/.test(n) ? Number(n) : null;
  const scored = list
    .map((s) => {
      const ar = normalizeQuery(s.nameAr);
      const en = s.nameEn.toLowerCase();
      if (asNum !== null && s.id === asNum) return { s, rank: 0 };
      if (ar === n || en === n) return { s, rank: 0 };
      if (ar.startsWith(n) || en.startsWith(n)) return { s, rank: 1 };
      if (ar.includes(n) || en.includes(n)) return { s, rank: 2 };
      return null;
    })
    .filter((x): x is { s: T; rank: number } => x !== null)
    .sort((a, b) => a.rank - b.rank || a.s.id - b.s.id);
  return scored.map((x) => x.s);
}
```

`web/src/components/SurahIndexFilter.tsx`:
```tsx
import { useMemo, useState } from 'react';
import { filterSurahs } from '../lib/surah-filter';
import { t, type Locale } from '../lib/strings';
import surahs from '../data/surahs.json';

export default function SurahIndexFilter({ locale = 'ar' as Locale }) {
  const [q, setQ] = useState('');
  const results = useMemo(() => filterSurahs(surahs.surahs, q), [q]);
  return (
    <div>
      <input
        type="search" value={q} onChange={(e) => setQ(e.target.value)}
        placeholder={t(locale, 'indexSearchPlaceholder')}
        aria-label={t(locale, 'indexSearchPlaceholder')}
        class="index-search"
      />
      {results.length === 0 && <p class="empty">{t(locale, 'noResults')}</p>}
      <ol class="surah-list">
        {results.map((s) => (
          <li key={s.id}>
            <a href={`/surah/${s.id}`}>
              <span class="surah-num">{s.id}</span>
              <span class="surah-name">{s.nameAr}</span>
              <span class="surah-meta">{s.revelationType === 'makkah' ? t(locale, 'chipMeccan') : t(locale, 'chipMedinan')} · {s.ayahCount}</span>
            </a>
          </li>
        ))}
      </ol>
    </div>
  );
}
```

`web/src/pages/quran.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import SurahIndexFilter from '../components/SurahIndexFilter.tsx';
import { t, defaultLocale } from '../lib/strings';
---
<BaseLayout title="المصحف — قرآن يَهدي">
  <h1 class="page-title">{t(defaultLocale, 'surahIndexTitle')}</h1>
  <SurahIndexFilter client:load />
</BaseLayout>
```

Append styles to `global.css`: `.surah-list { list-style: none; margin: 0 auto; padding: 0; max-width: 760px; } .surah-list a { display: flex; gap: 14px; align-items: baseline; padding: 12px 4px; border-bottom: 1px solid var(--hairline); color: var(--ink); text-decoration: none; } .surah-num { color: var(--gold-ink); min-width: 2.2em; } .surah-meta { margin-inline-start: auto; color: var(--muted); font-size: .85em; }`.

- [ ] **Step 4: e2e**

`web/tests/e2e/index.spec.ts`:
```ts
import { test, expect } from '@playwright/test';

test('index lists 114 surahs and filters', async ({ page }) => {
  await page.goto('/quran');
  await expect(page.locator('.surah-list a')).toHaveCount(114);
  await page.getByRole('searchbox').fill('الكهف');
  await expect(page.locator('.surah-list a')).toHaveCount(1);
  await expect(page.locator('.surah-list a')).toHaveAttribute('href', '/surah/18');
});
```

- [ ] **Step 5: Run all gates — expect PASS**

```bash
npm run check && npm run test && npm run test:e2e
```

- [ ] **Step 6: Commit**

```bash
git add web/src/lib/surah-filter.ts web/src/components/SurahIndexFilter.tsx web/src/pages/quran.astro web/tests/unit/surah-filter.test.ts web/tests/e2e/index.spec.ts web/src/styles/global.css
git commit -m "feat(web): surah index with ranked arabic-aware filtering"
```

---

### Task 8: Reader `/surah/[n]` + helpers (TDD)

**Files:**
- Create: `web/src/lib/arabic-digits.ts`, `web/src/lib/urls.ts`, `web/src/lib/surah-neighbors.ts`, `web/src/components/AyahBlock.astro`, `web/src/pages/surah/[n].astro`
- Test: `web/tests/unit/reader-lib.test.ts`, `web/tests/e2e/reader.spec.ts`

**Interfaces:**
- Consumes: `ayahs/<n>.json`, `surahs.json` (Task 5), `BaseLayout` (Task 6), `t` (Task 2).
- Produces: `toArabicDigits(n: number): string`; `SITE` + `surahUrl(n: number, ayah?: number): string`; `surahNeighbors(n: number): { prev: number | null; next: number | null }`; static pages `/surah/1`…`/surah/114` with `#ayah-{n}` anchors (the P4 share-link contract).

- [ ] **Step 1: Write the failing tests**

`web/tests/unit/reader-lib.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import { toArabicDigits } from '../../src/lib/arabic-digits';
import { surahUrl, SITE } from '../../src/lib/urls';
import { surahNeighbors } from '../../src/lib/surah-neighbors';

describe('toArabicDigits', () => {
  it('maps 0-9', () => expect(toArabicDigits(6236)).toBe('٦٢٣٦'));
  it('maps single digits', () => expect(toArabicDigits(255)).toBe('٢٥٥'));
});

describe('surahUrl', () => {
  it('builds surah url', () => expect(surahUrl(18)).toBe(`${SITE}/surah/18`));
  it('builds ayah anchor url', () => expect(surahUrl(2, 255)).toBe(`${SITE}/surah/2#ayah-255`));
});

describe('surahNeighbors', () => {
  it('first surah has no prev, has next 2', () => expect(surahNeighbors(1)).toEqual({ prev: null, next: 2 }));
  it('last surah has prev and no next', () => expect(surahNeighbors(114)).toEqual({ prev: 113, next: null }));
  it('middle surah has both', () => expect(surahNeighbors(18)).toEqual({ prev: 17, next: 19 }));
});
```

- [ ] **Step 2: Run — expect FAIL** (`npm run test`)

- [ ] **Step 3: Implement the three libs**

`web/src/lib/arabic-digits.ts`:
```ts
const AR = '٠١٢٣٤٥٦٧٨٩';
export function toArabicDigits(n: number): string {
  return String(n).replace(/\d/g, (d) => AR[Number(d)]);
}
```

`web/src/lib/urls.ts`:
```ts
export const SITE = 'https://quranyahdi.pages.dev';
export function surahUrl(n: number, ayah?: number): string {
  const base = `${SITE}/surah/${n}`;
  return ayah === undefined ? base : `${base}#ayah-${ayah}`;
}
```

`web/src/lib/surah-neighbors.ts`:
```ts
export function surahNeighbors(n: number): { prev: number | null; next: number | null } {
  return { prev: n > 1 ? n - 1 : null, next: n < 114 ? n + 1 : null };
}
```

- [ ] **Step 4: Implement reader components + page**

`web/src/components/AyahBlock.astro`:
```astro
---
import { toArabicDigits } from '../lib/arabic-digits';
interface Props { n: number; text: string; sajda: boolean }
const { n, text, sajda } = Astro.props;
---
<div class="ayah" id={`ayah-${n}`} data-n={n}>
  <p class="ayah-text">
    {text}<span class="medal" aria-hidden="true">{toArabicDigits(n)}</span>{sajda && <span class="sajda" title="سجدة">۩</span>}
  </p>
</div>
```

`web/src/pages/surah/[n].astro`:
```astro
---
import BaseLayout from '../../layouts/BaseLayout.astro';
import AyahBlock from '../../components/AyahBlock.astro';
import { surahNeighbors } from '../../lib/surah-neighbors';
import { t, defaultLocale } from '../../lib/strings';
import surahs from '../../data/surahs.json';

export function getStaticPaths() {
  return surahs.surahs.map((s) => ({ params: { n: String(s.id) }, props: { surah: s } }));
}
const { surah } = Astro.props as { surah: (typeof surahs.surahs)[number] };
const locale = defaultLocale;
const { prev, next } = surahNeighbors(surah.id);
const data = (await import(`../../data/ayahs/${surah.id}.json`)).default as {
  surah: number;
  ayahs: { n: number; juz: number; page: number; u: string; i: string; sajda: boolean }[];
};
const title = `سورة ${surah.nameAr} — قرآن يَهدي`;
---
<BaseLayout title={title} preloadFont>
  <article class="reader">
    <header class="reader-head">
      <h1>سورة {surah.nameAr}</h1>
      <p class="meta">{surah.revelationType === 'makkah' ? t(locale, 'chipMeccan') : t(locale, 'chipMedinan')} · {surah.ayahCount} آية</p>
    </header>
    <div class="ayahs">
      {data.ayahs.map((a) => <AyahBlock n={a.n} text={a.u} sajda={a.sajda} />)}
    </div>
    <nav class="reader-nav">
      {prev !== null ? <a href={`/surah/${prev}`}>{t(locale, 'readerPrev')}</a> : <a href="/quran">{t(locale, 'backToIndex')}</a>}
      {next !== null && <a href={`/surah/${next}`}>{t(locale, 'readerNext')}</a>}
    </nav>
  </article>
</BaseLayout>
```

Append reader styles to `global.css` (from the approved mockup tokens):
```css
.reader { max-width: 760px; margin-inline: auto; padding: 26px 20px 60px; }
.reader-head { text-align: center; padding-bottom: 18px; border-bottom: 1px solid var(--hairline); }
.reader-head h1 { margin: 0 0 6px; font-size: 1.7rem; }
.reader-head .meta { margin: 0; color: var(--muted); font-size: .9rem; }
.ayah { padding: 14px 2px; border-bottom: 1px solid var(--hairline); }
.ayah-text {
  margin: 0;
  font-family: 'HafsSmart', 'me_quran', serif;
  font-size: 21px; line-height: 2.15; color: var(--ink);
}
.medal {
  display: inline-flex; align-items: center; justify-content: center;
  width: 27px; height: 27px; border-radius: 50%;
  border: 1px solid var(--gold-line);
  box-shadow: inset 0 0 0 2px var(--surface), inset 0 0 0 3px var(--gold-line);
  color: var(--gold-ink); font-family: 'Cairo', sans-serif; font-size: 12px;
  vertical-align: middle; margin-inline-start: 6px;
}
.sajda { color: var(--gold-ink); margin-inline-start: 6px; }
.reader-nav { display: flex; justify-content: space-between; margin-top: 22px; }
.reader-nav a { color: var(--accent); text-decoration: none; font-weight: 700; }
```

- [ ] **Step 5: e2e reader smoke**

`web/tests/e2e/reader.spec.ts`:
```ts
import { test, expect } from '@playwright/test';

test('surah 2 renders 286 ayahs with anchors and the real quran font', async ({ page }) => {
  await page.goto('/surah/2');
  await expect(page.locator('.ayah')).toHaveCount(286);
  await expect(page.locator('#ayah-255')).toHaveCount(1);
  await expect(page).toHaveTitle(/سورة البقرة/);
  const fontReady = await page.evaluate(async () => {
    await document.fonts.ready;
    return document.fonts.check('16px HafsSmart');
  });
  expect(fontReady).toBe(true);
});

test('prev/next edges', async ({ page }) => {
  await page.goto('/surah/1');
  await expect(page.getByRole('link', { name: 'كل السور' })).toBeVisible();
  await page.goto('/surah/114');
  await expect(page.getByRole('link', { name: 'السورة السابقة' })).toBeVisible();
});
```

- [ ] **Step 6: Run full gates + e2e — expect PASS**

```bash
npm run check && npm run test && npm run test:e2e && npm run build
```
Also verify build output: 114 pages generated (`dist/surah/` contains `1/index.html` … `114/index.html`).

- [ ] **Step 7: Commit**

```bash
git add web/src/lib/arabic-digits.ts web/src/lib/urls.ts web/src/lib/surah-neighbors.ts web/src/components/AyahBlock.astro web/src/pages/surah web/tests/unit/reader-lib.test.ts web/tests/e2e/reader.spec.ts web/src/styles/global.css
git commit -m "feat(web): 114 surah reader pages with ayah anchors, medallions and font check"
```

---

### Task 9: Cloudflare Pages deploy + docs + close-out

**Files:**
- Create: `web/README.md`
- Modify: `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` (one line: `--gold-ink` day `#8A6520` → `#7E5C1D` — AA-margin refinement, cite Task 3's test)
- Modify: `docs/campaign-ledger.md` (append web-P1 close-out entry)

**Interfaces:**
- Consumes: the pushed... **no** — deployment preview works from the repo connection; push decision belongs to the owner (see Notes). All gates green before this task.

- [ ] **Step 1: Owner action (manual, guided) — create the Pages project**

In Cloudflare dashboard → Workers & Pages → Create → Pages → Connect to Git → repo `mostafasayed118/Quran-App` → settings: **Root directory `web`**, Build command `npm ci && npm run build`, Build output directory `dist`, env var `NODE_VERSION=22`. First build runs on the connected branch; **production branch = `main`** (first production deploy lands with the owner's next push — not part of this plan).

- [ ] **Step 2: Verify the preview deployment**

Open the Pages preview URL for the build. Expected: home renders with AR/RTL, header + toggle, `/quran` lists 114, `/surah/18` renders Kahf with medallions. (If the project name `quranyahdi` is taken, pick `quran-yahdi-web` and update `site` in `astro.config.mjs` + `SITE` in `web/src/lib/urls.ts` + spec W4 + this note — one small commit: `chore(web): pin pages.dev project name`.)

- [ ] **Step 3: Write `web/README.md`**

Contents (exact):
```markdown
# Quran Yahdi Web

Public website + online reader for قرآن يَهدي. Astro 7 static site — see
`docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` for the full design.

## Dev
- `npm ci`
- `npm run dev` — dev server
- `npm run gates` — check + unit tests + build (required before every commit)
- `npm run test:e2e` — Playwright smoke (chromium; installs on first run)

## Data
Quran text lives in `src/data/` and is **generated, never hand-edited**:

```
dart run tools/export_web_data.dart   # from repo root; reads assets/db/quran.sqlite
```

Re-run it only when the app's DB changes; commit the regenerated JSON.

## Deploy
Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
```

- [ ] **Step 4: Update the spec's gold token line**

In the spec's token table, change the `--gold-ink` day cell from `#8A6520` to `#7E5C1D` with a trailing note: `(AA margin — enforced by web/tests/unit/contrast.test.ts)`.

- [ ] **Step 5: Ledger close-out**

Append to `docs/campaign-ledger.md` a `WEB-P1` entry: date, commit list (`git log --oneline` of the web commits), gates evidence (check/test counts/build + e2e pass), deployed preview URL, deviations (if any), and "push deferred to owner GO".

- [ ] **Step 6: Final full gate run + commit**

```bash
cd web && npm run gates && npm run test:e2e && (Get-ChildItem -Recurse dist -File | Measure-Object).Count && cd ..
```
Expected: all green; dist file count well under **2,000** (Cloudflare free cap is 20,000 — spec §5 budget).

```bash
git add web/README.md docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md docs/campaign-ledger.md
git commit -m "docs(web): p1 close-out — readme, spec token refinement, ledger entry"
```

---

## Plan notes (why these choices)

- The Dart generator reads the **shipped sqlite** (not the source JSONs) so web text is identical-by-construction with the app; the drift/Windows path is already proven by `tools/build_quran_db.dart`.
- Search index generation is **P2** (the generator gains a `--search` output; the normalization algorithm will live once, in TS, with the client normalizing records at load — recorded as a P2 refinement of spec §3.5).
- Playwright CI wiring is P2; in P1 e2e runs locally on Windows (chromium).
- `surahUrl()` is built and tested now because `/surah/{n}#ayah-{a}` is the **share-link contract** the app-side P4 work binds to — the contract is frozen here.
- Night background gradient ships via `body::before` (token-driven, no gradient in components); reduced-motion disables its transition.
