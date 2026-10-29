// Budgets (spec §5): reader ships <=30KB gzip JS pre-interaction; quran index <=25KB; dist < 2000 files.
//
// Closure model: the walk follows BOTH static and dynamic import specifiers, so a
// page's real JS closure is measured instead of silently ignoring the lazily
// loaded chunks (the previous version dropped every dynamic import(), which hid
// the 210KB gzip verse index behind a passing 25KB quran budget).
//   direct  - <script src> in the page HTML (or an astro-island endpoint): fetched on load.
//   static  - reached through a static import from a loaded chunk: fetched on load.
//   dynamic - reached through a dynamic import(): fetched only when that code path runs,
//             so it is NOT pre-interaction JS. Lazy chunks are reported on their own
//             lines with their own ceilings.
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { basename, dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gzipSync } from 'node:zlib';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const DIST = join(ROOT, 'dist');
const HEADERS = join(ROOT, 'public', '_headers');

const READER_JS_BUDGET_BYTES = 30 * 1024;
const QURAN_JS_BUDGET_BYTES = 25 * 1024;
const HOME_JS_BUDGET_BYTES = 25 * 1024;
const PRAYER_JS_BUDGET_BYTES = 25 * 1024;
const CITY_JS_BUDGET_BYTES = 25 * 1024;
const RECITERS_JS_BUDGET_BYTES = 25 * 1024;
const EN_HOME_JS_BUDGET_BYTES = 25 * 1024;
const FILE_BUDGET = 2000;
// The committed verse index (src/data/search-index.json) is a lazily loaded data
// chunk: it must not be charged against a page's pre-interaction budget, but it
// must still be bounded.
const SEARCH_INDEX_GZIP_BUDGET_BYTES = 240 * 1024;
// The EN index is a separate, larger asset (6,236 records, ~304.56 KB gzip): its
// own ceiling keeps the AR index bounded independently.
const EN_SEARCH_INDEX_GZIP_BUDGET_BYTES = 360 * 1024;
// Every other lazily imported chunk (today: the reciters snapshot) shares this ceiling.
const LAZY_CHUNK_GZIP_BUDGET_BYTES = 64 * 1024;
// Per-page CSS the browser must parse before the first paint.
// Raised 8 → 10 KB on 2026-10-29 (owner decision): the home page is now a full
// design (heritage.css ~1.2k lines, shared by AR and EN), and 8 KB forced
// byte-shaving on every edit. Every other page still sits far below this.
const CSS_GZIP_BUDGET_BYTES = 10 * 1024;
// Every shipped woff2 face, preloaded or not.
const FONT_PAYLOAD_BUDGET_BYTES = 280 * 1024;
// The runtime-fetched prayer-times JSON: the whole payload the city pages can
// download, and the largest single city file.
const PRAYER_TIMES_PAYLOAD_BUDGET_BYTES = 4 * 1024 * 1024;
const PRAYER_TIMES_FILE_BUDGET_BYTES = 64 * 1024;
// The heaviest built HTML page. The ayah pages carry the full surah text, so they sit
// in the hundreds of KB: the ceiling guards against a runaway page, not page weight.
// The EN surah pages now inline the full English translation (surah 2 is ~536 KB;
// the AR surah page stays ~451 KB).
const HTML_PAGE_BUDGET_BYTES = 640 * 1024;

const PAGES = [
  {
    rel: 'surah/2/index.html',
    budget: READER_JS_BUDGET_BYTES,
    label: 'reader',
    note: 'spec §5',
    showFileCount: true,
  },
  {
    rel: 'quran/index.html',
    budget: QURAN_JS_BUDGET_BYTES,
    label: 'quran',
    note: 'surah index (island-free)',
    showFileCount: false,
    expectsSearchIndex: true,
  },
  {
    rel: 'en/quran/index.html',
    budget: QURAN_JS_BUDGET_BYTES,
    label: 'en-quran',
    note: 'english surah index (island-free)',
    showFileCount: false,
    expectsSearchIndex: true,
    searchIndexLocale: 'en',
  },
  {
    rel: 'index.html',
    budget: HOME_JS_BUDGET_BYTES,
    label: 'home',
    note: 'landing page',
    showFileCount: false,
  },
  {
    rel: 'prayer-times/index.html',
    budget: PRAYER_JS_BUDGET_BYTES,
    label: 'prayer-times',
    note: 'prayer times index',
    showFileCount: false,
  },
  {
    rel: 'prayer-times/eg-cairo/index.html',
    budget: CITY_JS_BUDGET_BYTES,
    label: 'prayer-city',
    note: 'one prayer-times city',
    showFileCount: false,
  },
  {
    rel: 'reciters/index.html',
    budget: RECITERS_JS_BUDGET_BYTES,
    label: 'reciters',
    note: 'reciters index',
    showFileCount: false,
  },
  {
    rel: 'en/index.html',
    budget: EN_HOME_JS_BUDGET_BYTES,
    label: 'en-home',
    note: 'english landing page',
    showFileCount: false,
  },
];

// Static import/"export ... from" forms.
const STATIC_SPECIFIER = /\b(?:import|export)(?![\w$.(])(?:[^'"]*?\bfrom\s*)?['"]([^'"]+)['"]/g;
// Dynamic import() forms. Vite emits the specifier as a template literal.
const DYNAMIC_SPECIFIER = /\bimport\s*\(\s*['"`]([^'"`]+)['"`]\s*\)/g;
const INLINE_SCRIPT = /<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g;
// The styles Astro inlines into the page are parsed before the first paint too.
const INLINE_STYLE = /<style(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/style>/g;
// Vite names a chunk after its source: src/data/search-index.json -> search-index.<hash>.js
const SEARCH_INDEX_CHUNK = /^search-index\.[\w-]+\.js$/;
// The search worker fetches the index as a hashed JSON asset instead of bundling it.
// The EN asset is a distinct file: it must never satisfy the AR page's expectation.
const SEARCH_INDEX_ASSET = /^search-index(?!-en)[-.][\w-]+\.json$/;
const EN_SEARCH_INDEX_ASSET = /^search-index-en[-.][\w-]+\.json$/;
// A worker is its own chunk; the page points at it with `new Worker(new URL(...))`.
const WORKER_SPECIFIER = /new Worker\(\s*new URL\(\s*['"`]([^'"`]+)['"`]/g;
// A chunk can fetch a hashed asset by its absolute URL (the worker fetches the index).
const ASSET_SPECIFIER = /['"`](\/_astro\/[^'"`]+)['"`]/g;

const kb = (bytes) => `${(bytes / 1024).toFixed(2)} KB`;

const resolveFromPage = (src) => join(DIST, decodeURIComponent(src.split(/[?#]/)[0]));
const resolveFromChunk = (chunk, specifier) =>
  join(dirname(chunk), decodeURIComponent(specifier.split(/[?#]/)[0]));

let fileCount = 0;
const htmlFiles = [];
const walk = (dir) => {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(path);
    } else {
      fileCount += 1;
      if (entry.name.endsWith('.html')) htmlFiles.push(path);
    }
  }
};
walk(DIST);

let searchIndex = null;
let searchIndexAsset = null;
let enSearchIndexAsset = null;
const lazyChunks = [];

function measurePage(page) {
  const pagePath = join(DIST, page.rel);
  if (!existsSync(pagePath)) {
    console.error(`budget: ${pagePath} not found - run "npm run build" first`);
    process.exit(1);
  }

  const html = readFileSync(pagePath, 'utf8');

  const jsFiles = [];
  const visited = new Set();
  const assetFiles = [];
  const addJsFile = (file, kind) => {
    if (visited.has(file)) return;
    visited.add(file);
    const bytes = readFileSync(file);
    jsFiles.push({ file, kind, gzip: gzipSync(bytes).length, source: bytes.toString('utf8') });
  };
  const addAssetFile = (file) => {
    if (assetFiles.some((entry) => entry.file === file)) return;
    assetFiles.push({ file, gzip: gzipSync(readFileSync(file)).length });
  };
  const addRef = (src) => {
    if (!src.startsWith('/')) {
      console.error(`budget: ${page.rel} has a non-absolute script src ${src}`);
      process.exit(1);
    }
    const file = resolveFromPage(src);
    if (!existsSync(file)) {
      console.error(`budget: ${page.rel} references missing asset ${src}`);
      process.exit(1);
    }
    addJsFile(file, 'direct');
  };

  for (const match of html.matchAll(/<script[^>]*\ssrc="([^"]+)"/g)) {
    addRef(match[1]);
  }

  // React island endpoints are fetched at hydrate time, so they count as direct refs.
  for (const match of html.matchAll(/<astro-island\b[^>]*>/g)) {
    for (const attr of ['component-url', 'renderer-url']) {
      const hit = new RegExp(`\\b${attr}="([^"]+)"`).exec(match[0]);
      if (hit) addRef(hit[1]);
    }
  }

  // The closure: static AND dynamic specifiers, followed transitively.
  for (let i = 0; i < jsFiles.length; i++) {
    for (const match of jsFiles[i].source.matchAll(STATIC_SPECIFIER)) {
      const specifier = match[1];
      if (!specifier.startsWith('./') && !specifier.startsWith('../')) continue;
      const file = resolveFromChunk(jsFiles[i].file, specifier);
      if (!existsSync(file)) {
        console.error(
          `budget: ${basename(jsFiles[i].file)} statically imports missing asset ${specifier}`,
        );
        process.exit(1);
      }
      addJsFile(file, 'static');
    }
    for (const match of jsFiles[i].source.matchAll(DYNAMIC_SPECIFIER)) {
      const specifier = match[1];
      if (!specifier.startsWith('./') && !specifier.startsWith('../')) continue;
      const file = resolveFromChunk(jsFiles[i].file, specifier);
      if (!existsSync(file)) {
        console.error(
          `budget: ${basename(jsFiles[i].file)} dynamically imports missing asset ${specifier}`,
        );
        process.exit(1);
      }
      addJsFile(file, 'dynamic');
    }
    // A worker is a separate chunk the page starts on demand; it belongs to the
    // page's closure and must be measured, not ignored.
    for (const match of jsFiles[i].source.matchAll(WORKER_SPECIFIER)) {
      const file = resolveFromPage(match[1]);
      if (!existsSync(file)) {
        console.error(`budget: ${page.rel} starts a missing worker ${match[1]}`);
        process.exit(1);
      }
      addJsFile(file, 'dynamic');
    }
    // A chunk can fetch a hashed asset (the search worker fetches the index).
    for (const match of jsFiles[i].source.matchAll(ASSET_SPECIFIER)) {
      const file = resolveFromPage(match[1]);
      if (!existsSync(file)) {
        console.error(`budget: ${page.rel} fetches a missing asset ${match[1]}`);
        process.exit(1);
      }
      addAssetFile(file);
    }
  }

  const inline = [];
  for (const match of html.matchAll(INLINE_SCRIPT)) {
    inline.push({ bytes: match[1].length, gzip: gzipSync(Buffer.from(match[1])).length });
  }

  // The page's CSS: every stylesheet the browser must parse before the first
  // paint, plus the styles Astro inlines into the page.
  const cssFiles = [];
  for (const match of html.matchAll(/<link\b[^>]*>/g)) {
    const tag = match[0];
    if (!/rel="stylesheet"/.test(tag)) continue;
    const href = /\shref="([^"]+)"/.exec(tag);
    if (!href) continue;
    const file = resolveFromPage(href[1]);
    if (!existsSync(file)) {
      console.error(`budget: ${page.rel} references missing stylesheet ${href[1]}`);
      process.exit(1);
    }
    cssFiles.push({ file, gzip: gzipSync(readFileSync(file)).length });
  }
  const inlineStyles = [];
  for (const match of html.matchAll(INLINE_STYLE)) {
    inlineStyles.push({ bytes: match[1].length, gzip: gzipSync(Buffer.from(match[1])).length });
  }
  const cssGzip =
    cssFiles.reduce((sum, entry) => sum + entry.gzip, 0) +
    inlineStyles.reduce((sum, entry) => sum + entry.gzip, 0);

  const direct = jsFiles.filter((entry) => entry.kind === 'direct');
  const staticImported = jsFiles.filter((entry) => entry.kind === 'static');
  const lazy = jsFiles.filter((entry) => entry.kind === 'dynamic');
  const directGzip = direct.reduce((sum, entry) => sum + entry.gzip, 0);
  const staticGzip = staticImported.reduce((sum, entry) => sum + entry.gzip, 0);
  const lazyGzip = lazy.reduce((sum, entry) => sum + entry.gzip, 0);
  const inlineGzip = inline.reduce((sum, entry) => sum + entry.gzip, 0);
  const preInteractionGzip = directGzip + staticGzip + inlineGzip;

  const pageSearchIndex = lazy.find((entry) => SEARCH_INDEX_CHUNK.test(basename(entry.file)));
  const pageSearchIndexAsset = assetFiles.find((entry) =>
    SEARCH_INDEX_ASSET.test(basename(entry.file)),
  );
  const pageEnSearchIndexAsset = assetFiles.find((entry) =>
    EN_SEARCH_INDEX_ASSET.test(basename(entry.file)),
  );
  const otherLazy = lazy.filter((entry) => entry !== pageSearchIndex);
  if (pageSearchIndex && !searchIndex) searchIndex = pageSearchIndex;
  if (pageSearchIndexAsset && !searchIndexAsset) searchIndexAsset = pageSearchIndexAsset;
  if (pageEnSearchIndexAsset && !enSearchIndexAsset) enSearchIndexAsset = pageEnSearchIndexAsset;
  for (const entry of otherLazy) {
    if (!lazyChunks.some((known) => known.file === entry.file)) lazyChunks.push(entry);
  }

  // A page is bound to its own locale's asset. The worker chunk carries both URLs,
  // so both assets show up in every page's file list - the binding must be explicit.
  const indexLocale = page.searchIndexLocale === 'en' ? 'en' : 'ar';
  const boundSearchIndexAsset =
    indexLocale === 'en' ? pageEnSearchIndexAsset : pageSearchIndexAsset;

  if (page.expectsSearchIndex && !pageSearchIndex && !boundSearchIndexAsset) {
    console.error(
      `budget: ${page.rel} no longer reaches the ${indexLocale.toUpperCase()} search index - the ` +
        `${indexLocale === 'en' ? 'EN_SEARCH_INDEX_GZIP_BUDGET_BYTES' : 'SEARCH_INDEX_GZIP_BUDGET_BYTES'} ` +
        `ceiling would be blind`,
    );
    process.exit(1);
  }

  return {
    page,
    jsFiles,
    direct,
    staticImported,
    lazy,
    otherLazy,
    pageSearchIndex,
    pageSearchIndexAsset: boundSearchIndexAsset,
    pageEnSearchIndexAsset,
    assetFiles,
    directGzip,
    staticGzip,
    lazyGzip,
    inline,
    inlineGzip,
    preInteractionGzip,
    cssFiles,
    inlineStyles,
    cssGzip,
    jsOk: preInteractionGzip <= page.budget,
    cssOk: cssGzip <= CSS_GZIP_BUDGET_BYTES,
  };
}

function printSection(result) {
  const { page, jsFiles, direct, staticImported, directGzip, staticGzip, inline, inlineGzip } =
    result;

  const rows = [
    ['metric', 'measured', 'budget', 'verdict'],
    [`${page.label} JS - direct refs`, `${kb(directGzip)} (${direct.length})`, '-', '-'],
    [`${page.label} JS - static closure`, `${kb(staticGzip)} (${staticImported.length})`, '-', '-'],
    [`${page.label} JS - inline scripts`, `${kb(inlineGzip)} (${inline.length})`, '-', '-'],
    [
      `${page.label} JS - pre-interaction`,
      kb(result.preInteractionGzip),
      kb(page.budget),
      result.jsOk ? 'PASS' : 'FAIL',
    ],
    [
      `${page.label} JS - lazy chunks`,
      `${kb(result.otherLazy.reduce((sum, e) => sum + e.gzip, 0))} (${result.otherLazy.length})`,
      kb(LAZY_CHUNK_GZIP_BUDGET_BYTES),
      result.otherLazy.every((e) => e.gzip <= LAZY_CHUNK_GZIP_BUDGET_BYTES) ? 'PASS' : 'FAIL',
    ],
    [
      `${page.label} CSS`,
      `${kb(result.cssGzip)} (${result.cssFiles.length} file(s) + ${result.inlineStyles.length} inline)`,
      kb(CSS_GZIP_BUDGET_BYTES),
      result.cssOk ? 'PASS' : 'FAIL',
    ],
  ];
  if (page.showFileCount) {
    const filesOk = fileCount < FILE_BUDGET;
    rows.push([
      'dist file count',
      String(fileCount),
      String(FILE_BUDGET),
      filesOk ? 'PASS' : 'FAIL',
    ]);
  }

  const widths = rows[0].map((_, col) => Math.max(...rows.map((row) => row[col].length)));
  console.log(`Budgets - dist/${page.rel} (${page.note})`);
  for (const row of rows) {
    console.log(row.map((cell, col) => cell.padEnd(widths[col])).join('  '));
  }
  console.log(`${page.label} JS files (${jsFiles.length}):`);
  for (const entry of jsFiles) {
    console.log(`  [${entry.kind}] ${basename(entry.file)} ${kb(entry.gzip)}`);
  }
}

/** Every woff2 face the site ships, preloaded or not. */
function measureFontPayload() {
  const dir = join(DIST, 'fonts');
  if (!existsSync(dir)) return { bytes: 0, files: [] };
  const files = [];
  const walk = (current) => {
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const path = join(current, entry.name);
      if (entry.isDirectory()) walk(path);
      else if (entry.name.endsWith('.woff2')) {
        files.push({ name: entry.name, bytes: statSync(path).size });
      }
    }
  };
  walk(dir);
  return { bytes: files.reduce((sum, f) => sum + f.bytes, 0), files };
}

/** The prayer-times JSON the city pages fetch at runtime. */
function measurePrayerTimesPayload() {
  const dir = join(DIST, 'data', 'prayer-times');
  if (!existsSync(dir)) return { bytes: 0, files: 0, largest: 0 };
  let bytes = 0;
  let files = 0;
  let largest = 0;
  const walk = (current) => {
    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const path = join(current, entry.name);
      if (entry.isDirectory()) {
        walk(path);
        continue;
      }
      const size = statSync(path).size;
      bytes += size;
      files += 1;
      if (size > largest) largest = size;
    }
  };
  walk(dir);
  return { bytes, files, largest };
}

/** The heaviest built HTML page. */
function measureLargestHtml() {
  let largest = { file: '', bytes: 0 };
  for (const file of htmlFiles) {
    const bytes = statSync(file).size;
    if (bytes > largest.bytes) largest = { file, bytes };
  }
  return largest;
}

/**
 * The CSP allows the remaining inline scripts by sha256 hash. Recompute the hashes
 * from the built HTML and fail when the policy no longer covers one of them: a stale
 * hash silently breaks the theme on every page.
 */
function verifyCspInlineScripts() {
  const headers = readFileSync(HEADERS, 'utf8');
  const csp = /Content-Security-Policy:\s*(.+)/.exec(headers)?.[1]?.trim() ?? '';
  const scriptSrc = /script-src([^;]*)/.exec(csp)?.[1] ?? '';
  const allowed = new Set([...scriptSrc.matchAll(/'sha256-([^']+)'/g)].map((m) => m[1]));
  const seen = new Map();
  for (const file of htmlFiles) {
    const html = readFileSync(file, 'utf8');
    for (const match of html.matchAll(INLINE_SCRIPT)) {
      const hash = createHash('sha256').update(match[1], 'utf8').digest('base64');
      const entry = seen.get(hash) ?? { count: 0, sample: file };
      entry.count += 1;
      seen.set(hash, entry);
    }
  }
  const uncovered = [...seen.entries()].filter(([hash]) => !allowed.has(hash));
  return {
    csp,
    scriptSrc,
    allowed,
    seen,
    uncovered,
    unsafeInline: /script-src[^;]*'unsafe-inline'/.test(scriptSrc),
  };
}

const results = PAGES.map(measurePage);
for (const result of results) printSection(result);

const fontPayload = measureFontPayload();
const prayerTimesPayload = measurePrayerTimesPayload();
const largestHtml = measureLargestHtml();
const cspCheck = verifyCspInlineScripts();
const filesOk = fileCount < FILE_BUDGET;
const fontsOk = fontPayload.bytes <= FONT_PAYLOAD_BUDGET_BYTES;
const htmlOk = largestHtml.bytes <= HTML_PAGE_BUDGET_BYTES;
const indexBytes = Math.max(searchIndex?.gzip ?? 0, searchIndexAsset?.gzip ?? 0);
const searchIndexOk = indexBytes > 0 && indexBytes <= SEARCH_INDEX_GZIP_BUDGET_BYTES;
const enIndexBytes = enSearchIndexAsset?.gzip ?? 0;
const enSearchIndexOk = enIndexBytes > 0 && enIndexBytes <= EN_SEARCH_INDEX_GZIP_BUDGET_BYTES;
const lazyOk = lazyChunks.every((entry) => entry.gzip <= LAZY_CHUNK_GZIP_BUDGET_BYTES);
const cspOk = !cspCheck.unsafeInline && cspCheck.uncovered.length === 0 && cspCheck.seen.size > 0;
const prayerTimesOk =
  prayerTimesPayload.bytes <= PRAYER_TIMES_PAYLOAD_BUDGET_BYTES &&
  prayerTimesPayload.largest <= PRAYER_TIMES_FILE_BUDGET_BYTES;

const globalRows = [
  ['metric', 'measured', 'budget', 'verdict'],
  ['dist file count', String(fileCount), String(FILE_BUDGET), filesOk ? 'PASS' : 'FAIL'],
  [
    'font payload (woff2)',
    `${kb(fontPayload.bytes)} (${fontPayload.files.length})`,
    kb(FONT_PAYLOAD_BUDGET_BYTES),
    fontsOk ? 'PASS' : 'FAIL',
  ],
  [
    'prayer-times JSON (total)',
    `${kb(prayerTimesPayload.bytes)} (${prayerTimesPayload.files} file(s))`,
    kb(PRAYER_TIMES_PAYLOAD_BUDGET_BYTES),
    prayerTimesPayload.bytes <= PRAYER_TIMES_PAYLOAD_BUDGET_BYTES ? 'PASS' : 'FAIL',
  ],
  [
    'prayer-times JSON (largest city)',
    kb(prayerTimesPayload.largest),
    kb(PRAYER_TIMES_FILE_BUDGET_BYTES),
    prayerTimesPayload.largest <= PRAYER_TIMES_FILE_BUDGET_BYTES ? 'PASS' : 'FAIL',
  ],
  [
    'largest built HTML page',
    `${kb(largestHtml.bytes)} (${relative(DIST, largestHtml.file)})`,
    kb(HTML_PAGE_BUDGET_BYTES),
    htmlOk ? 'PASS' : 'FAIL',
  ],
  [
    'search index (lazy chunk)',
    searchIndexAsset
      ? `${kb(searchIndexAsset.gzip)} (${basename(searchIndexAsset.file)})`
      : searchIndex
        ? kb(searchIndex.gzip)
        : 'not found',
    kb(SEARCH_INDEX_GZIP_BUDGET_BYTES),
    searchIndexOk ? 'PASS' : 'FAIL',
  ],
  [
    'search index EN (asset)',
    enSearchIndexAsset
      ? `${kb(enSearchIndexAsset.gzip)} (${basename(enSearchIndexAsset.file)})`
      : 'not found',
    kb(EN_SEARCH_INDEX_GZIP_BUDGET_BYTES),
    enSearchIndexOk ? 'PASS' : 'FAIL',
  ],
  [
    'other lazy chunks (max)',
    lazyChunks.length ? kb(Math.max(...lazyChunks.map((e) => e.gzip))) : '-',
    kb(LAZY_CHUNK_GZIP_BUDGET_BYTES),
    lazyOk ? 'PASS' : 'FAIL',
  ],
  [
    'CSP inline-script hashes',
    `${cspCheck.seen.size} inline script(s) / ${cspCheck.allowed.size} allowed`,
    'all hashed',
    cspOk ? 'PASS' : 'FAIL',
  ],
];

const widths = globalRows[0].map((_, col) => Math.max(...globalRows.map((row) => row[col].length)));
console.log('Budgets - site wide');
for (const row of globalRows) {
  console.log(row.map((cell, col) => cell.padEnd(widths[col])).join('  '));
}
if (cspCheck.seen.size > 0) {
  console.log('inline scripts in dist (sha256 of the exact bytes, one line per distinct script):');
  for (const [hash, entry] of cspCheck.seen) {
    console.log(
      `  ${cspCheck.allowed.has(hash) ? '[hashed]' : '[MISSING]'} sha256-${hash} (${entry.count} page(s))`,
    );
  }
}

for (const result of results) {
  if (!result.jsOk) {
    console.error(
      `BUDGET BREACH: ${result.page.label} JS ${kb(result.preInteractionGzip)} gzip exceeds ` +
        `${kb(result.page.budget)} (${result.jsFiles.length} files incl. static-import closure + ` +
        `${result.inline.length} inline scripts)`,
    );
  }
  if (!result.cssOk) {
    console.error(
      `BUDGET BREACH: ${result.page.label} CSS ${kb(result.cssGzip)} gzip exceeds ${kb(CSS_GZIP_BUDGET_BYTES)}`,
    );
  }
}
if (!filesOk) {
  console.error(`BUDGET BREACH: dist holds ${fileCount} files, budget is < ${FILE_BUDGET}`);
}
if (!fontsOk) {
  console.error(
    `BUDGET BREACH: font payload ${kb(fontPayload.bytes)} exceeds ${kb(FONT_PAYLOAD_BUDGET_BYTES)}`,
  );
}
if (!htmlOk) {
  console.error(
    `BUDGET BREACH: largest HTML page ${kb(largestHtml.bytes)} exceeds ${kb(HTML_PAGE_BUDGET_BYTES)}`,
  );
}
if (!searchIndexOk) {
  console.error(
    `BUDGET BREACH: search index ${kb(indexBytes)} exceeds ` +
      `${kb(SEARCH_INDEX_GZIP_BUDGET_BYTES)}`,
  );
}
if (!enSearchIndexOk) {
  console.error(
    `BUDGET BREACH: english search index ${kb(enIndexBytes)} exceeds ` +
      `${kb(EN_SEARCH_INDEX_GZIP_BUDGET_BYTES)}`,
  );
}
if (!prayerTimesOk) {
  console.error(
    `BUDGET BREACH: prayer-times JSON ${kb(prayerTimesPayload.bytes)} (largest city ` +
      `${kb(prayerTimesPayload.largest)}) exceeds ` +
      `${kb(PRAYER_TIMES_PAYLOAD_BUDGET_BYTES)} / ${kb(PRAYER_TIMES_FILE_BUDGET_BYTES)}`,
  );
}
if (!lazyOk) {
  console.error(`BUDGET BREACH: a lazy chunk exceeds ${kb(LAZY_CHUNK_GZIP_BUDGET_BYTES)}`);
}
if (cspCheck.unsafeInline) {
  console.error("BUDGET BREACH: script-src still allows 'unsafe-inline'");
}
for (const [hash, entry] of cspCheck.uncovered) {
  console.error(
    `BUDGET BREACH: inline script is not covered by the CSP sha256 list - add 'sha256-${hash}' ` +
      `(first seen in ${entry.sample})`,
  );
}

const ok =
  results.every((result) => result.jsOk && result.cssOk) &&
  filesOk &&
  fontsOk &&
  htmlOk &&
  searchIndexOk &&
  enSearchIndexOk &&
  lazyOk &&
  prayerTimesOk &&
  cspOk;
process.exit(ok ? 0 : 1);
