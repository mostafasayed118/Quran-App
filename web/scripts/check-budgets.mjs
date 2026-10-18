// Budgets (spec §5): reader ships ≤30KB gzip JS pre-interaction; dist < 2000 files.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const DIST = join(ROOT, 'dist');
const PAGE = join(DIST, 'surah', '2', 'index.html');

const JS_BUDGET_BYTES = 30 * 1024;
const FILE_BUDGET = 2000;

const kb = (bytes) => `${(bytes / 1024).toFixed(2)} KB`;

if (!existsSync(PAGE)) {
  console.error(`budget: ${PAGE} not found - run "npm run build" first`);
  process.exit(1);
}

const html = readFileSync(PAGE, 'utf8');

const external = [];
for (const match of html.matchAll(/<script[^>]*\ssrc="([^"]+)"/g)) {
  const src = match[1];
  if (!src.startsWith('/')) continue;
  const file = join(DIST, decodeURIComponent(src.split(/[?#]/)[0]));
  if (!existsSync(file)) {
    console.error(`budget: reader page references missing asset ${src}`);
    process.exit(1);
  }
  external.push({ src, gzip: gzipSync(readFileSync(file)).length });
}

const inline = [];
for (const match of html.matchAll(/<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g)) {
  inline.push(gzipSync(Buffer.from(match[1])).length);
}

let fileCount = 0;
const walk = (dir) => {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) walk(join(dir, entry.name));
    else fileCount += 1;
  }
};
walk(DIST);

const externalGzip = external.reduce((sum, ref) => sum + ref.gzip, 0);
const inlineGzip = inline.reduce((sum, bytes) => sum + bytes, 0);
const totalGzip = externalGzip + inlineGzip;
const jsOk = totalGzip <= JS_BUDGET_BYTES;
const filesOk = fileCount < FILE_BUDGET;

const rows = [
  ['metric', 'measured', 'budget', 'verdict'],
  ['reader JS - external refs', `${kb(externalGzip)} (${external.length})`, '-', '-'],
  ['reader JS - inline scripts', `${kb(inlineGzip)} (${inline.length})`, '-', '-'],
  ['reader JS - total gzip', kb(totalGzip), kb(JS_BUDGET_BYTES), jsOk ? 'PASS' : 'FAIL'],
  ['dist file count', String(fileCount), String(FILE_BUDGET), filesOk ? 'PASS' : 'FAIL'],
];

const widths = rows[0].map((_, col) => Math.max(...rows.map((row) => row[col].length)));
console.log(`Budgets - dist/surah/2/index.html (spec §5)`);
for (const row of rows) {
  console.log(row.map((cell, col) => cell.padEnd(widths[col])).join('  '));
}

if (!jsOk) {
  console.error(
    `BUDGET BREACH: reader JS ${kb(totalGzip)} gzip exceeds ${kb(JS_BUDGET_BYTES)} ` +
      `(${external.length} external chunks + ${inline.length} inline scripts)`,
  );
}
if (!filesOk) {
  console.error(`BUDGET BREACH: dist holds ${fileCount} files, budget is < ${FILE_BUDGET}`);
}
process.exit(jsOk && filesOk ? 0 : 1);
