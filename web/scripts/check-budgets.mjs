// Budgets (spec §5): reader ships ≤30KB gzip JS pre-interaction; quran index ≤100KB; dist < 2000 files.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const DIST = join(ROOT, 'dist');

const READER_JS_BUDGET_BYTES = 30 * 1024;
const QURAN_JS_BUDGET_BYTES = 100 * 1024;
const FILE_BUDGET = 2000;

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
    note: 'surah index island',
    showFileCount: false,
  },
];

// Static import/"export ... from" forms only; dynamic import() is deliberately excluded.
const STATIC_SPECIFIER = /\b(?:import|export)(?![\w$.(])(?:[^'"]*?\bfrom\s*)?['"]([^'"]+)['"]/g;

const kb = (bytes) => `${(bytes / 1024).toFixed(2)} KB`;

const resolveFromPage = (src) => join(DIST, decodeURIComponent(src.split(/[?#]/)[0]));
const resolveFromChunk = (chunk, specifier) =>
  join(dirname(chunk), decodeURIComponent(specifier.split(/[?#]/)[0]));

let fileCount = 0;
const walk = (dir) => {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) walk(join(dir, entry.name));
    else fileCount += 1;
  }
};
walk(DIST);

function measurePage(page) {
  const pagePath = join(DIST, page.rel);
  if (!existsSync(pagePath)) {
    console.error(`budget: ${pagePath} not found - run "npm run build" first`);
    process.exit(1);
  }

  const html = readFileSync(pagePath, 'utf8');

  const jsFiles = [];
  const visited = new Set();
  const addJsFile = (file, kind) => {
    if (visited.has(file)) return;
    visited.add(file);
    const bytes = readFileSync(file);
    jsFiles.push({ file, kind, gzip: gzipSync(bytes).length, source: bytes.toString('utf8') });
  };
  const addRef = (src) => {
    if (!src.startsWith('/')) return;
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
      addJsFile(file, 'imported');
    }
  }

  const inline = [];
  for (const match of html.matchAll(/<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g)) {
    inline.push(gzipSync(Buffer.from(match[1])).length);
  }

  const direct = jsFiles.filter((entry) => entry.kind === 'direct');
  const imported = jsFiles.filter((entry) => entry.kind === 'imported');
  const directGzip = direct.reduce((sum, entry) => sum + entry.gzip, 0);
  const importedGzip = imported.reduce((sum, entry) => sum + entry.gzip, 0);
  const externalGzip = directGzip + importedGzip;
  const inlineGzip = inline.reduce((sum, bytes) => sum + bytes, 0);
  const totalGzip = externalGzip + inlineGzip;

  return {
    page,
    jsFiles,
    direct,
    imported,
    directGzip,
    importedGzip,
    inline,
    inlineGzip,
    totalGzip,
    jsOk: totalGzip <= page.budget,
  };
}

function printSection(result) {
  const { page, jsFiles, direct, imported, directGzip, importedGzip, inline, inlineGzip } = result;

  const rows = [
    ['metric', 'measured', 'budget', 'verdict'],
    [`${page.label} JS - direct refs`, `${kb(directGzip)} (${direct.length})`, '-', '-'],
    [`${page.label} JS - imported closure`, `${kb(importedGzip)} (${imported.length})`, '-', '-'],
    [`${page.label} JS - inline scripts`, `${kb(inlineGzip)} (${inline.length})`, '-', '-'],
    [`${page.label} JS - total gzip`, kb(result.totalGzip), kb(page.budget), result.jsOk ? 'PASS' : 'FAIL'],
  ];
  if (page.showFileCount) {
    const filesOk = fileCount < FILE_BUDGET;
    rows.push(['dist file count', String(fileCount), String(FILE_BUDGET), filesOk ? 'PASS' : 'FAIL']);
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

const results = PAGES.map(measurePage);
for (const result of results) printSection(result);

for (const result of results) {
  if (!result.jsOk) {
    console.error(
      `BUDGET BREACH: ${result.page.label} JS ${kb(result.totalGzip)} gzip exceeds ${kb(result.page.budget)} ` +
        `(${result.jsFiles.length} files incl. static-import closure + ${result.inline.length} inline scripts)`,
    );
  }
}
const filesOk = fileCount < FILE_BUDGET;
if (!filesOk) {
  console.error(`BUDGET BREACH: dist holds ${fileCount} files, budget is < ${FILE_BUDGET}`);
}
process.exit(results.every((result) => result.jsOk) && filesOk ? 0 : 1);
