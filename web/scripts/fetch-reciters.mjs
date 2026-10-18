// One-shot: refresh the committed reciter snapshot. Run from repo root: node web/scripts/fetch-reciters.mjs
import { writeFileSync } from 'node:fs';
const res = await fetch('https://mp3quran.net/api/v3/reciters?language=ar');
if (!res.ok) throw new Error(`HTTP ${res.status}`);
const data = await res.json();
if (!Array.isArray(data.reciters) || data.reciters.length < 50) throw new Error('suspicious payload');
writeFileSync(new URL('../src/data/reciters-snapshot.json', import.meta.url), JSON.stringify(data));
console.log(`OK: ${data.reciters.length} reciters written`);
