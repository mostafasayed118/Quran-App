# Web P2 — Features Implementation Plan (الصوت + البحث + التفاسير + تجربة القارئ)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the P2 feature layer to قرآن يَهدي web: persistent surah audio player + `/reciters` browser (mp3quran, parity with the app), full-text Arabic search, tafsir/translation panels, reader settings + per-ayah actions (copy/share/bookmark) + screen-reader text layer, plus the budget gates deferred from P1.

**Architecture:** Still pure-static Astro in `web/`; all interactivity is vanilla-TS client islands (the `/quran` search/surah filter may stay the existing React island — it is outside the reader budget). A single persistent player singleton lives in a `transition:persist` region under Astro's `<ClientRouter />`, driven by CustomEvents (`qy:play`, `qy:toggle`, `qy:seek`). Verse text rules are absolute: `u` (PUA glyphs) renders with HafsSmart; **`i` (plain Arabic) is the ONLY source for copy, search, bookmarks and screen readers**.

**Tech Stack:** Astro 7 (`<ClientRouter />` view transitions + `transition:persist`) · vanilla TS islands · Vitest · Playwright (with request routing for all external hosts) · committed fixtures.

**Spec:** `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` (§3.4–3.7 sources, §4 pages, §5 budgets, §7 P2 row) — read it. P1 is live at `https://quranyahdi.pages.dev` (`fe91b0e`..probe-verified; Cloudflare auto-deploys `main`).

## Global Constraints

- **Free-only; no cookies/analytics/accounts.** All external data sources are the FREE CORS-open ones verified live on 2026-10-18:
  - Reciters: `https://mp3quran.net/api/v3/reciters?language=ar` — 243 reciters; reciter `{id,name,letter,date,moshaf[]}`; moshaf `{id,name,rewaya_id,server,surah_total,moshaf_type,surah_list}`; sample server `https://cdn.mp3quran.net/audio/ibrahim-akhdar/r1/`. Audio file = `{server}/{surah 3-padded}.mp3`.
  - Translations (fawazahmed0, per-surah): `https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/{edition}/{surah}.json` → `{chapter:[{chapter,verse,text}]}`.
  - Tafsir (spa5k, per-surah): `https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.2/tafsir/{edition}/{surah}.json` → array indexed by ayah-1, `[{text}]`.
- **App parity (mirror the app's proven rules — do not invent):**
  - Featured reciter ids (PM-pinned in the app; NEVER extend): `[51, 123, 118, 92, 102, 54, 30, 4, 5]` — featured first, then name, then id.
  - Trusted audio servers only: `https://` + host `mp3quran.net` or `*.mp3quran.net` — drop everything else at parse time.
  - Respect `surah_list` (CSV of available surahs) and `surah_total` per moshaf.
- **PUA rule (non-negotiable):** display text = `u` + HafsSmart; copy/share-text/search/bookmarks/sr-only = `i`. Never copy `u`.
- **Reader budget:** `/surah/*` shipped JS ≤ 30KB gzip INCLUDING the ClientRouter runtime; keep all reader islands vanilla TS (no React on reader pages; `/quran` React island stays).
- **Colors only via tokens**; **strings via `web/src/lib/strings.ts`** (extend the dict; AR + EN parity test must stay green — count will grow).
- **e2e determinism:** every test that touches an external host (`mp3quran.net`, `cdn.mp3quran.net`, `cdn.jsdelivr.net`) MUST `page.route(...)` to committed fixtures in `web/tests/fixtures/`. No live network in tests.
- **Gates before every commit (inside `web/`):** `npm run check` + `npm run test` + `npm run test:e2e` + `npm run build` — plus `npm run budget` from Task 9 onward.
- **NO PUSH.** Conventional commits, explicit pathspecs; foreign in-flight app edits are never staged; `.vscode/settings.json`, `web/.vscode/**`, `web/AGENTS.md` never staged.
- Vitest stale-cache trap: on `Unknown variable dynamic import`, clear `web/node_modules/.vitest-cache`.
- Docs truth-up duties: `web/README.md` feature section + spec §7 status + `docs/campaign-ledger.md` close-out (Task 10).

---

### Task 1: Reciters data lib + snapshot + fetch-with-fallback (TDD)

**Files:**
- Create: `web/src/lib/reciters.ts`
- Create: `web/scripts/fetch-reciters.mjs` (build-prep one-shot; Node 22, built-ins only)
- Create (output, committed): `web/src/data/reciters-snapshot.json`
- Test: `web/tests/unit/reciters.test.ts`

**Interfaces:**
- Produces: `FEATURED_RECITER_IDS: readonly number[]`; `interface MoshafRow { rowId: string; reciterId: number; reciterName: string; moshafId: number; moshafName: string; server: string; surahList: number[]; surahTotal: number }`; `parseReciters(payload: unknown): MoshafRow[]`; `sortReciters(rows: MoshafRow[]): MoshafRow[]`; `isTrustedAudioServer(server: string): boolean`; `surahAudioUrl(server: string, surah: number): string`; `fetchReciters(): Promise<MoshafRow[]>` (live API → fallback to committed snapshot via `import snapshot from '../data/reciters-snapshot.json'`); `isFeaturedRow(row: MoshafRow): boolean`. Consumed by Tasks 2, 5, 8.

- [ ] **Step 1: Write the failing tests**

`web/tests/unit/reciters.test.ts`:
```ts
import { describe, it, expect } from 'vitest';
import {
  parseReciters, sortReciters, isTrustedAudioServer, surahAudioUrl, isFeaturedRow,
  FEATURED_RECITER_IDS, type MoshafRow,
} from '../../src/lib/reciters';
import snapshot from '../../src/data/reciters-snapshot.json';

const good = {
  reciters: [
    { id: 999, name: 'زمزم', letter: 'ز', date: 'x', moshaf: [{ id: 1, name: 'حفص', rewaya_id: 1, server: 'https://cdn.mp3quran.net/a/zamzam/r1/', surah_total: 3, moshaf_type: 11, surah_list: '1,2,3' }] },
    { id: 51, name: 'مشاري العفاسي', letter: 'م', date: 'x', moshaf: [{ id: 5, name: 'حفص عن عاصم - مرتل', rewaya_id: 1, server: 'https://cdn.mp3quran.net/a/afasy/r1/', surah_total: 114, moshaf_type: 11, surah_list: '' }] },
    { id: 7, name: 'شرير', letter: 'ش', date: 'x', moshaf: [{ id: 2, name: 'http خبيث', rewaya_id: 1, server: 'http://evil.example.com/e/', surah_total: 114, moshaf_type: 11, surah_list: '' }] },
    { id: 'bad' },
  ],
};

describe('parseReciters', () => {
  it('drops malformed reciters and untrusted servers', () => {
    const rows = parseReciters(good);
    expect(rows).toHaveLength(2);
    expect(rows.every((r) => r.server.startsWith('https://'))).toBe(true);
  });
  it('parses surah_list CSV and keeps totals', () => {
    const rows = parseReciters(good);
    const zam = rows.find((r) => r.reciterId === 999)!;
    expect(zam.surahList).toEqual([1, 2, 3]);
    expect(zam.rowId).toBe('999-1');
    expect(zam.surahTotal).toBe(3);
  });
  it('tolerates junk hosts and non-object payloads', () => {
    expect(parseReciters(null)).toEqual([]);
    expect(parseReciters({ reciters: 'nope' })).toEqual([]);
    expect(isTrustedAudioServer('https://notmp3quran.net/x/')).toBe(false);
    expect(isTrustedAudioServer('https://cdn.mp3quran.net/x/')).toBe(true);
    expect(isTrustedAudioServer('https://mp3quran.net/x/')).toBe(true);
  });
});

describe('sortReciters', () => {
  it('ranks featured ids first (PM order), then by name, then id', () => {
    const rows: MoshafRow[] = [
      { rowId: '999-1', reciterId: 999, reciterName: 'زمزم', moshafId: 1, moshafName: '', server: 'https://cdn.mp3quran.net/z/', surahList: [], surahTotal: 114 },
      { rowId: '51-5', reciterId: 51, reciterName: 'مشاري العفاسي', moshafId: 5, moshafName: '', server: 'https://cdn.mp3quran.net/a/', surahList: [], surahTotal: 114 },
      { rowId: '123-1', reciterId: 123, reciterName: 'ياسر الدوسري', moshafId: 1, moshafName: '', server: 'https://cdn.mp3quran.net/y/', surahList: [], surahTotal: 114 },
    ];
    const sorted = sortReciters(rows);
    expect(sorted.map((r) => r.reciterId)).toEqual([51, 123, 999]);
    expect(isFeaturedRow(sorted[0])).toBe(true);
    expect(isFeaturedRow(sorted[2])).toBe(false);
    expect(FEATURED_RECITER_IDS[0]).toBe(51);
  });
});

describe('surahAudioUrl', () => {
  it('pads to 3 digits and normalizes the trailing slash', () => {
    expect(surahAudioUrl('https://cdn.mp3quran.net/a/r1/', 1)).toBe('https://cdn.mp3quran.net/a/r1/001.mp3');
    expect(surahAudioUrl('https://cdn.mp3quran.net/a/r1', 114)).toBe('https://cdn.mp3quran.net/a/r1/114.mp3');
  });
});

describe('committed snapshot', () => {
  it('is parseable and contains the featured reciters', () => {
    const rows = parseReciters(snapshot);
    expect(rows.length).toBeGreaterThan(50);
    for (const id of FEATURED_RECITER_IDS) {
      expect(rows.some((r) => r.reciterId === id), `featured ${id} in snapshot`).toBe(true);
    }
  });
});
```

- [ ] **Step 2: Run RED** — `npm run test` (missing module + missing snapshot).

- [ ] **Step 3: Implement `web/src/lib/reciters.ts`** (verbatim; mirrors `lib/features/recitation/data/reciter_repository.dart` semantics):

```ts
import snapshot from '../data/reciters-snapshot.json';

/** PM-pinned featured reciters (parity with the app). Never extend without a grant. */
export const FEATURED_RECITER_IDS = [51, 123, 118, 92, 102, 54, 30, 4, 5] as const;

export interface MoshafRow {
  rowId: string;
  reciterId: number;
  reciterName: string;
  moshafId: number;
  moshafName: string;
  server: string;
  surahList: number[];
  surahTotal: number;
}

export function isTrustedAudioServer(server: string): boolean {
  let uri: URL;
  try { uri = new URL(server); } catch { return false; }
  return uri.protocol === 'https:' &&
    (uri.hostname === 'mp3quran.net' || uri.hostname.endsWith('.mp3quran.net'));
}

export function parseSurahList(csv: string): number[] {
  return csv.split(',').map((p) => Number.parseInt(p.trim(), 10)).filter((n) => Number.isFinite(n));
}

export function parseReciters(payload: unknown): MoshafRow[] {
  const reciters = (payload as { reciters?: unknown } | null)?.reciters;
  if (!Array.isArray(reciters)) return [];
  const rows: MoshafRow[] = [];
  for (const r of reciters) {
    if (typeof r !== 'object' || r === null) continue;
    const rec = r as Record<string, unknown>;
    if (typeof rec.id !== 'number' || !Array.isArray(rec.moshaf)) continue;
    for (const m of rec.moshaf) {
      if (typeof m !== 'object' || m === null) continue;
      const mo = m as Record<string, unknown>;
      if (typeof mo.id !== 'number') continue;
      if (typeof mo.server !== 'string' || !isTrustedAudioServer(mo.server)) continue;
      rows.push({
        rowId: `${rec.id}-${mo.id}`,
        reciterId: rec.id,
        reciterName: typeof rec.name === 'string' ? rec.name : '',
        moshafId: mo.id,
        moshafName: typeof mo.name === 'string' ? mo.name : '',
        server: mo.server,
        surahList: typeof mo.surah_list === 'string' ? parseSurahList(mo.surah_list) : [],
        surahTotal: typeof mo.surah_total === 'number' ? mo.surah_total : 0,
      });
    }
  }
  return rows;
}

export function isFeaturedRow(row: MoshafRow): boolean {
  return (FEATURED_RECITER_IDS as readonly number[]).includes(row.reciterId);
}

export function sortReciters(rows: MoshafRow[]): MoshafRow[] {
  const rank = new Map<number, number>(FEATURED_RECITER_IDS.map((id, i) => [id, i]));
  return [...rows].sort((a, b) => {
    const ra = rank.get(a.reciterId) ?? FEATURED_RECITER_IDS.length;
    const rb = rank.get(b.reciterId) ?? FEATURED_RECITER_IDS.length;
    if (ra !== rb) return ra - rb;
    const byName = a.reciterName.localeCompare(b.reciterName, 'ar');
    return byName !== 0 ? byName : a.rowId.localeCompare(b.rowId);
  });
}

export function surahAudioUrl(server: string, surah: number): string {
  const base = server.endsWith('/') ? server : `${server}/`;
  return `${base}${String(surah).padStart(3, '0')}.mp3`;
}

/** Live API with committed-snapshot fallback (spec §3.4). */
export async function fetchReciters(): Promise<MoshafRow[]> {
  try {
    const res = await fetch('https://mp3quran.net/api/v3/reciters?language=ar', { signal: AbortSignal.timeout(15000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const rows = parseReciters(await res.json());
    if (rows.length === 0) throw new Error('empty reciter payload');
    return rows;
  } catch {
    return parseReciters(snapshot);
  }
}
```

`web/scripts/fetch-reciters.mjs`:
```js
// One-shot: refresh the committed reciter snapshot. Run from repo root: node web/scripts/fetch-reciters.mjs
import { writeFileSync } from 'node:fs';
const res = await fetch('https://mp3quran.net/api/v3/reciters?language=ar');
if (!res.ok) throw new Error(`HTTP ${res.status}`);
const data = await res.json();
if (!Array.isArray(data.reciters) || data.reciters.length < 50) throw new Error('suspicious payload');
writeFileSync(new URL('../src/data/reciters-snapshot.json', import.meta.url), JSON.stringify(data));
console.log(`OK: ${data.reciters.length} reciters written`);
```

- [ ] **Step 4: Generate the snapshot** — `node web/scripts/fetch-reciters.mjs` → `OK: 243 reciters written` (live; expect 200-260).
- [ ] **Step 5: Run GREEN** — `npm run test` (all green incl. snapshot checks).
- [ ] **Step 6: Commit**

```bash
git add web/src/lib/reciters.ts web/scripts/fetch-reciters.mjs web/src/data/reciters-snapshot.json web/tests/unit/reciters.test.ts
git commit -m "feat(web): reciters lib with app-parity trust rules + committed snapshot"
```

---

### Task 2: Player core (vanilla TS, TDD)

**Files:**
- Create: `web/src/lib/player.ts`
- Test: `web/tests/unit/player.test.ts`

**Interfaces:**
- Consumes: `MoshafRow`, `surahAudioUrl`, `sortReciters` (Task 1); `settings` helper (`web/src/lib/settings.ts` — CREATE in this task: `readSetting<T>(key: string, fallback: T): T` / `writeSetting(key: string, value: unknown): void`, namespaced `qy:` — used by every later task).
- Produces: `interface PlayerState { row: MoshafRow | null; surah: number | null; status: 'idle' | 'loading' | 'playing' | 'paused' | 'error'; currentTime: number; duration: number }`; `createPlayer(audio: HTMLAudioElement, deps: { urlFor(row: MoshafRow, surah: number): string })` → `{ play(row: MoshafRow, surah: number): void; toggle(): void; seekRatio(r: number): void; next(): void; prev(): void; state(): PlayerState; subscribe(fn: (s: PlayerState) => void): () => void }`; localStorage keys: `qy:player:row` (rowId), `qy:player:surah`. Playable surahs for a row = `row.surahList.length ? row.surahList : 1..114`.

- [ ] **Step 1: Write the failing tests** (`web/tests/unit/player.test.ts`) — a real behavior fake for `HTMLAudioElement`:

```ts
import { describe, it, expect, beforeEach } from 'vitest';
import { createPlayer } from '../../src/lib/player';
import type { MoshafRow } from '../../src/lib/reciters';

class FakeAudio {
  src = ''; currentTime = 0; duration = 0; paused = true;
  private listeners = new Map<string, Set<() => void>>();
  addEventListener(t: string, fn: () => void) { (this.listeners.get(t) ?? this.listeners.set(t, new Set()).get(t)!).add(fn); }
  removeEventListener(t: string, fn: () => void) { this.listeners.get(t)?.delete(fn); }
  emit(t: string) { this.listeners.get(t)?.forEach((fn) => fn()); }
  play() { this.paused = false; this.emit('playing'); return Promise.resolve(); }
  pause() { this.paused = true; this.emit('pause'); }
  load() { /* noop */ }
}

const row: MoshafRow = {
  rowId: '51-5', reciterId: 51, reciterName: 'مشاري العفاسي', moshafId: 5, moshafName: 'حفص',
  server: 'https://cdn.mp3quran.net/a/afasy/r1/', surahList: [1, 2, 18], surahTotal: 3,
};

let audio: FakeAudio;
let urls: string[];
beforeEach(() => { audio = new FakeAudio(); urls = []; });

function make() {
  return createPlayer(audio as unknown as HTMLAudioElement, {
    urlFor: (r, s) => { urls.push(`${r.rowId}:${s}`); return `https://cdn.example/${s}.mp3`; },
  });
}

describe('player', () => {
  it('play() sets the url and reports loading→playing', async () => {
    const p = make();
    const seen: string[] = [];
    p.subscribe((s) => seen.push(s.status));
    p.play(row, 18);
    expect(audio.src).toBe('https://cdn.example/18.mp3');
    expect(urls).toEqual(['51-5:18']);
    await Promise.resolve();
    expect(seen[0]).toBe('loading');
    expect(p.state().status).toBe('playing');
  });
  it('next/prev cycle through the row surah list, wrapping', () => {
    const p = make();
    p.play(row, 2);
    p.next(); expect(p.state().surah).toBe(18);
    p.next(); expect(p.state().surah).toBe(1);
    p.prev(); expect(p.state().surah).toBe(18);
  });
  it('toggle pauses and resumes without re-setting src', () => {
    const p = make();
    p.play(row, 1);
    audio.currentTime = 5;
    p.toggle(); expect(audio.paused).toBe(true);
    p.toggle(); expect(audio.paused).toBe(false);
    expect(audio.currentTime).toBe(5);
  });
  it('seekRatio clamps to [0,1] × duration', () => {
    const p = make();
    p.play(row, 1);
    audio.duration = 100;
    p.seekRatio(0.5); expect(audio.currentTime).toBe(50);
    p.seekRatio(2); expect(audio.currentTime).toBe(100);
  });
  it('audio error event lands in error state with the id retained', () => {
    const p = make();
    p.play(row, 1);
    audio.emit('error');
    expect(p.state().status).toBe('error');
    expect(p.state().surah).toBe(1);
  });
  it('falls back to 1..114 when surahList is empty', () => {
    const full = { ...row, surahList: [] as number[], surahTotal: 114 };
    const p = make();
    p.play(full, 114);
    p.next(); expect(p.state().surah).toBe(1);
  });
});
```

- [ ] **Step 2: Run RED** — `npm run test`.

- [ ] **Step 3: Implement `web/src/lib/settings.ts` + `web/src/lib/player.ts`**

`web/src/lib/settings.ts`:
```ts
const PREFIX = 'qy:';
export function readSetting<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(PREFIX + key);
    return raw === null ? fallback : (JSON.parse(raw) as T);
  } catch { return fallback; }
}
export function writeSetting(key: string, value: unknown): void {
  try { localStorage.setItem(PREFIX + key, JSON.stringify(value)); } catch { /* private mode */ }
}
```

`web/src/lib/player.ts`:
```ts
import { surahAudioUrl, type MoshafRow } from './reciters';
import { readSetting, writeSetting } from './settings';

export interface PlayerState {
  row: MoshafRow | null;
  surah: number | null;
  status: 'idle' | 'loading' | 'playing' | 'paused' | 'error';
  currentTime: number;
  duration: number;
}

export interface Player {
  play(row: MoshafRow, surah: number): void;
  toggle(): void;
  seekRatio(r: number): void;
  next(): void;
  prev(): void;
  state(): PlayerState;
  subscribe(fn: (s: PlayerState) => void): () => void;
}

function surahsFor(row: MoshafRow): number[] {
  return row.surahList.length > 0 ? row.surahList : Array.from({ length: 114 }, (_, i) => i + 1);
}

export function createPlayer(
  audio: HTMLAudioElement,
  deps: { urlFor?: (row: MoshafRow, surah: number) => string } = {},
): Player {
  const urlFor = deps.urlFor ?? ((row, surah) => surahAudioUrl(row.server, surah));
  const listeners = new Set<(s: PlayerState) => void>();
  let state: PlayerState = { row: null, surah: null, status: 'idle', currentTime: 0, duration: 0 };

  const emit = () => listeners.forEach((fn) => fn(state));
  const set = (patch: Partial<PlayerState>) => { state = { ...state, ...patch }; emit(); };

  audio.addEventListener('playing', () => set({ status: 'playing' }));
  audio.addEventListener('pause', () => { if (state.status !== 'idle') set({ status: 'paused' }); });
  audio.addEventListener('timeupdate', () => set({ currentTime: audio.currentTime }));
  audio.addEventListener('loadedmetadata', () => set({ duration: audio.duration }));
  audio.addEventListener('error', () => { if (state.surah !== null) set({ status: 'error' }); });

  function load(row: MoshafRow, surah: number) {
    set({ row, surah, status: 'loading', currentTime: 0, duration: 0 });
    writeSetting('player:row', row.rowId);
    writeSetting('player:surah', surah);
    audio.src = urlFor(row, surah);
    audio.load();
    void audio.play().catch(() => { /* autoplay/abort — error event covers real failures */ });
  }

  return {
    play(row, surah) { load(row, surah); },
    toggle() { if (audio.paused) void audio.play().catch(() => {}); else audio.pause(); },
    seekRatio(r) { if (audio.duration > 0) audio.currentTime = Math.min(Math.max(r, 0), 1) * audio.duration; },
    next() {
      if (!state.row || state.surah === null) return;
      const list = surahsFor(state.row);
      const i = list.indexOf(state.surah);
      load(state.row, list[(i + 1) % list.length]);
    },
    prev() {
      if (!state.row || state.surah === null) return;
      const list = surahsFor(state.row);
      const i = list.indexOf(state.surah);
      load(state.row, list[(i - 1 + list.length) % list.length]);
    },
    state: () => state,
    subscribe(fn) { listeners.add(fn); return () => listeners.delete(fn); },
  };
}

let singleton: Player | null = null;
export function getPlayer(): Player {
  if (singleton) return singleton;
  const audio = document.getElementById('qy-audio') as HTMLAudioElement | null;
  if (!audio) throw new Error('qy-audio element missing');
  singleton = createPlayer(audio);
  return singleton;
}
```

- [ ] **Step 4: GREEN** — `npm run test`.
- [ ] **Step 5: Commit**

```bash
git add web/src/lib/settings.ts web/src/lib/player.ts web/tests/unit/player.test.ts
git commit -m "feat(web): settings helper + persistent audio player core with TDD"
```

---

### Task 3: Persistent mini-player UI + ClientRouter + e2e (with routed fixtures)

**Files:**
- Create: `web/src/components/MiniPlayer.astro`, `web/src/pages/reciters.astro` (minimal stub — built out in Task 8)
- Modify: `web/src/layouts/BaseLayout.astro` (add `<ClientRouter />` + persist region + fixture-safe player root)
- Modify: `web/src/styles/global.css` (mini-player styles), `web/src/lib/strings.ts` (player strings)
- Create: `web/tests/fixtures/silent.wav` (1s silent WAV, ~8KB — generate ONCE with the Python snippet in Step 2)
- Create: `web/tests/e2e/player.spec.ts`
- Modify: `web/tests/e2e/*.spec.ts` if needed for ClientRouter nav (selectors only if breakage occurs)

**Interfaces:**
- Consumes: `getPlayer` (Task 2).
- Produces: DOM contract `#qy-player-region` (`transition:persist`), `<audio id="qy-audio">`, controls `[data-qy="toggle"|"next"|"prev"]`, `[data-qy="seek"]`, labels `[data-qy="title"]`, `[data-qy="reciter"]`, `[data-qy="time"]`; events `qy:play` (detail `{ row: MoshafRow, surah: number }`) and `qy:toggle`. Later tasks dispatch/consume ONLY these.

- [ ] **Step 1: Layout wiring** — in `BaseLayout.astro` head add `import { ClientRouter } from 'astro:transitions';` + `<ClientRouter />`; before `<Footer>` add:

```html
<div id="qy-player-region" transition:persist="qy-player">
  <MiniPlayer locale={locale} />
</div>
```

`MiniPlayer.astro` (verbatim; vanilla, hidden when idle):
```astro
---
import { t, type Locale } from '../lib/strings';
interface Props { locale?: Locale }
const { locale = 'ar' } = Astro.props;
---
<div class="mini-player" data-qy="bar" hidden>
  <audio id="qy-audio" preload="none"></audio>
  <button type="button" class="mp-btn" data-qy="prev" aria-label={t(locale, 'playerPrev')}>⏮</button>
  <button type="button" class="mp-btn mp-main" data-qy="toggle" aria-label={t(locale, 'playerPlay')}>▶</button>
  <button type="button" class="mp-btn" data-qy="next" aria-label={t(locale, 'playerNext')}>⏭</button>
  <div class="mp-meta">
    <span class="mp-title" data-qy="title"></span>
    <span class="mp-reciter" data-qy="reciter"></span>
  </div>
  <div class="mp-track"><div class="mp-bar" data-qy="seek" role="slider" aria-label={t(locale, 'playerSeek')}><i></i></div></div>
  <span class="mp-time" data-qy="time"></span>
  <button type="button" class="mp-btn" data-qy="close" aria-label={t(locale, 'playerClose')}>✕</button>
</div>
<script>
  import { getPlayer } from '../lib/player';
  import { toArabicDigits } from '../lib/arabic-digits';
  import type { MoshafRow } from '../lib/reciters';

  function init() {
    const bar = document.querySelector('[data-qy="bar"]') as HTMLElement;
    if (!bar || (bar as unknown as { __qyInit?: boolean }).__qyInit) return;
    (bar as unknown as { __qyInit?: boolean }).__qyInit = true;
    const player = getPlayer();
    const $ = (sel: string) => bar.querySelector(`[data-qy="${sel}"]`) as HTMLElement;
    const fmt = (s: number) => (Number.isFinite(s) ? toArabicDigits(Math.floor(s / 60)) + ':' + toArabicDigits(String(Math.floor(s % 60)).padStart(2, '0')) : '');

    const render = () => {
      const st = player.state();
      if (!st.row || st.surah === null) { bar.hidden = true; return; }
      bar.hidden = false;
      $('title').textContent = st.row.reciterName;
      $('reciter').textContent = st.row.moshafName;
      $('time').textContent = st.duration ? `${fmt(st.currentTime)} / ${fmt(st.duration)}` : '';
      $('toggle').textContent = st.status === 'playing' ? '⏸' : '▶';
      const i = bar.querySelector('[data-qy="seek"] i') as HTMLElement;
      i.style.width = st.duration ? `${Math.min(100, (st.currentTime / st.duration) * 100)}%` : '0%';
    };
    player.subscribe(render);
    $('toggle').addEventListener('click', () => player.toggle());
    $('next').addEventListener('click', () => player.next());
    $('prev').addEventListener('click', () => player.prev());
    $('seek').addEventListener('click', (e) => {
      const rect = $('seek').getBoundingClientRect();
      player.seekRatio(((e as MouseEvent).clientX - rect.left) / rect.width);
    });
    $('close').addEventListener('click', () => { bar.hidden = true; });
    document.addEventListener('qy:play', (e) => {
      const { row, surah } = (e as CustomEvent<{ row: MoshafRow; surah: number }>).detail;
      player.play(row, surah);
    });
    document.addEventListener('qy:toggle', () => player.toggle());
    render();
  }
  init();
  document.addEventListener('astro:after-swap', init); // ClientRouter re-entry safety
</script>
```

Add strings: `playerPlay`, `playerPause` (unused label ok), `playerPrev`, `playerNext`, `playerSeek`, `playerClose`, `playerError` — AR + EN (keep parity test green; update pinned counts if the strings test pins totals — it iterates keys generically, no pin — safe).

Append `.mini-player` styles to `global.css` (fixed bottom bar, `var(--player-bg)`, hairline top, 48px buttons on touch via `min-height:48px` media pointer:coarse — the deferred 48px polish applies here).

- [ ] **Step 2: Fixture + e2e** — create the silent audio fixture ONCE with this exact snippet (Python stdlib, no deps), then commit the generated file:

```python
# run from repo root:  python - <<this snippet>>  writes web/tests/fixtures/silent.wav
import wave
with wave.open(r"web/tests/fixtures/silent.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(1); w.setframerate(8000)
    w.writeframes(bytes(8000))  # 1 second of 8-bit silence
```

`web/tests/e2e/player.spec.ts`:

```ts
import { test, expect } from '@playwright/test';
import reciters from '../fixtures/reciters-2.json'; // write this fixture: 2 reciters (featured 51 + one plain), trusted servers

test('player: play from reciters page persists across SPA navigation', async ({ page }) => {
  await page.route('**/mp3quran.net/api/v3/reciters**', (r) => r.fulfill({ json: reciters }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/reciters/');
  await page.locator('[data-reciter-play]').first().click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="title"]')).not.toBeEmpty();
  // Persistence is a CLIENT-ROUTER behavior: navigate via an in-app link, never page.goto (that reloads).
  await page.locator('header a[href="/quran"]').click();
  await page.waitForURL('**/quran/**');
  await expect(page.locator('[data-qy="bar"]')).toBeVisible();          // persisted region survived
  await expect(page.locator('[data-qy="toggle"]')).toHaveText('⏸');     // still playing
});
```
NOTE for the implementer: also click a surah link from `/quran/` into `/surah/1/` and assert the bar persists there too (second SPA hop) before closing the test.
Add `web/tests/fixtures/reciters-2.json` (2 reciters: id 51 featured + id 999, valid modern payload shape).

- [ ] **Step 3: Run gates** — `npm run check && npm run test && npm run test:e2e && npm run build`; confirm reader page JS still ≤30KB gzip by eyeballing `dist/_astro/*.js` referenced by `dist/surah/2/index.html` (budget gate formalized in Task 9). NOTE: `/reciters` page is part of THIS task — the minimal list page with `[data-reciter-play]` buttons is created here (2 rows: featured name + play icon dispatching `qy:play` with surah 1) and fully built out in Task 8.
- [ ] **Step 4: Commit**

```bash
git add web/src/components/MiniPlayer.astro web/src/layouts/BaseLayout.astro web/src/styles/global.css web/src/lib/strings.ts web/src/pages/reciters.astro web/tests/fixtures web/tests/e2e/player.spec.ts
git commit -m "feat(web): persistent mini-player with ClientRouter + routed e2e"
```

---

### Task 4: Reader settings + sr-only `i` layer + Arabic digits everywhere (TDD)

**Files:**
- Create: `web/src/lib/arabic.ts` (extract + centralize the normalization chain) + `web/src/lib/reader-settings.ts`
- Modify: `web/src/lib/surah-filter.ts` (import shared `normalizeArabic`; DELETE its local copy + its private ARABIC_INDIC const), `web/src/lib/arabic-digits.ts` (add `toAsciiDigits` using its OWN alphabet constant — the one definition both directions share)
- Modify: `web/src/components/AyahBlock.astro` (sr-only layer + settings classes), `web/src/pages/surah/[n].astro` (meta digits via `toArabicDigits`, settings controls island), `web/src/styles/global.css` (`.sr-only`, font-size steps, imlaei font)
- Test: `web/tests/unit/reader-settings.test.ts`, `web/tests/unit/arabic.test.ts`, extend `web/tests/e2e/reader.spec.ts`

**Interfaces:**
- Produces: `normalizeArabic(input: string): string` in `arabic.ts` (the exact chain currently inside `normalizeQuery` — strip `[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]`, [أإآٱ]→ا, ى→ي, ة→ه, Arabic-Indic digits via `toAsciiDigits`) — ONE implementation, imported by surah-filter + Task 6 search; `toAsciiDigits(s: string): string` (in `arabic-digits.ts`, sharing its alphabet constant with `toArabicDigits`); reader settings `qy:reader` = `{ fontStep: 0|1|2|3, view: 'mushaf' | 'imlaei' }` with `readReaderSettings()/writeReaderSettings(patch)`; DOM: `.ayah-text` inner spans `.ayah-u[aria-hidden="true"]` + `.ayah-i.sr-only`; `html[data-reading-view="imlaei"]` flips which span is visible.

- [ ] **Step 1: Failing tests** — `arabic.test.ts` (7 cases moved from surah-filter + digit mapping), `reader-settings.test.ts` (defaults `{0,'mushaf'}`, JSON round-trip, invalid payload → defaults). Extend reader e2e:

```ts
test('ayah exposes plain Arabic to AT and Arabic digits in meta', async ({ page }) => {
  await page.goto('/surah/2/');
  const first = page.locator('.ayah').first();
  await expect(first.locator('.ayah-i')).toHaveText(/.+/);            // sr-only plain text exists
  await expect(first.locator('.ayah-u')).toHaveAttribute('aria-hidden', 'true');
  await expect(page.locator('.reader-head .meta')).toContainText('٢٨٦'); // Arabic-Indic, was 286
});
test('imlaei toggle swaps the visible span and persists', async ({ page }) => {
  await page.goto('/surah/1/');
  await page.getByRole('button', { name: 'إملائي' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-reading-view', 'imlaei');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-reading-view', 'imlaei');
});
```

- [ ] **Step 2: Implement**
  - `arabic.ts`: move the chain verbatim (`trim → lower → strip [\u064B-\u065F\u0670\u06D6-\u06ED\u0640] → [أإآٱ]→ا → ى→ي → ة→ه → digits`) as `normalizeArabic`; `surah-filter.ts` re-exports/imports it (its tests stay green, unchanged).
  - `reader-settings.ts` per interface.
  - `AyahBlock.astro` new body (call-site update in `[n].astro` is REQUIRED in the same step: `{data.ayahs.map((a) => <AyahBlock n={a.n} textUthmani={a.u} textImlaei={a.i} sajda={a.sajda} />)}` — Task 5 will ADD the `surah` prop when it adds the actions row):
```astro
---
import { toArabicDigits } from '../lib/arabic-digits';
interface Props { n: number; textUthmani: string; textImlaei: string; sajda: boolean }
const { n, textUthmani, textImlaei, sajda } = Astro.props;
---
<div class="ayah" id={`ayah-${n}`} data-n={n}>
  <p class="ayah-text" style="--ayah-size: calc(19px + var(--reader-step, 1) * 3px)">
    <span class="ayah-u" aria-hidden="true">{textUthmani}<span class="medal" aria-hidden="true">{toArabicDigits(n)}</span>{sajda && <span class="sajda" aria-hidden="true">۩</span>}</span>
    <span class="ayah-i sr-only">{textImlaei}</span>
  </p>
</div>
```
  - `[n].astro` reader-head: add controls island (vanilla `<script is:inline>`): buttons `إملائي/مصحفي` (`aria-pressed`), font-size −/＋ (clamped 0..3) → set `html[data-reading-view]` + `--reader-step` via `document.documentElement.style.setProperty` + `writeReaderSettings`; a pre-paint `is:inline` snippet in the page head area (or BaseLayout with prop) applies stored values on load (no flicker). Meta: `{toArabicDigits(surah.ayahCount)}`.
  - `global.css`: `.sr-only{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}`; `.ayah-text{font-family:'HafsSmart','me_quran',serif; font-size:var(--ayah-size)}`; `html[data-reading-view="imlaei"] .ayah-u{display:none}` + `html[data-reading-view="imlaei"] .ayah-i{position:static;width:auto;height:auto;clip-path:none;font-family:'Cairo',sans-serif;font-size:calc(var(--ayah-size) * .8);line-height:2.1}`.
- [ ] **Step 3: Gates green**; [ ] **Step 4: Commit**

```bash
git add web/src/lib/arabic.ts web/src/lib/reader-settings.ts web/src/lib/surah-filter.ts web/src/lib/arabic-digits.ts web/src/components/AyahBlock.astro web/src/pages/surah/[n].astro web/src/styles/global.css web/tests/unit/arabic.test.ts web/tests/unit/reader-settings.test.ts web/tests/e2e/reader.spec.ts
git commit -m "feat(web): reader settings, sr-only plain-Arabic layer, Arabic digits everywhere"
```

---

### Task 5: Per-ayah actions — copy/share/bookmark/play dispatch (TDD + e2e)

**Files:**
- Create: `web/src/lib/bookmarks.ts`, `web/src/lib/share.ts`
- Modify: `web/src/components/AyahBlock.astro` (actions row), `web/src/pages/surah/[n].astro` (header reciter picker + play button), `web/src/styles/global.css`
- Test: `web/tests/unit/bookmarks.test.ts`, `web/tests/unit/share.test.ts`, `web/tests/e2e/ayah-actions.spec.ts`, extend reader e2e

**Interfaces:**
- Consumes: `surahUrl` (P1 `urls.ts`), `writeSetting/readSetting` (Task 2), settings for picker `qy:reader` extended key `reciterRow` (rowId).
- Produces: `bookmarks.ts`: `isBookmarked(s,a): boolean`, `toggleBookmark(s,a): boolean` (returns new state), `listBookmarks(): {s:number;a:number}[]` (key `qy:bookmarks`); `share.ts`: `shareOrCopy(url: string, text: string): Promise<'shared'|'copied'>` (navigator.share → else clipboard); DOM: ayah actions `[data-ayah-action="copy"|"share"|"bookmark"|"listen"]` inside `.ayah-actions`, header `[data-qy="reader-play"]` + `[data-qy="reciter-pick"]` emitting `qy:play` with the picked row.

- [ ] **Step 1: Failing unit tests** — bookmarks toggle/persist/list/clear semantics (injected storage object for tests: `createBookmarkStore(storage)` returning the three funcs + `hitsFor` — then a thin singleton bound to `localStorage`); share: share path resolves 'shared' when `navigator.share` exists (fake), else clipboard write path returns 'copied' (fake clipboard asserting exact payload).
- [ ] **Step 2: Implement libs + UI.**
  - `AyahBlock.astro` actions row (inside `.ayah-text` block after the text):
```astro
<div class="ayah-actions">
  <button type="button" data-ayah-action="copy" data-surah={surah} data-ayah={n} aria-label="نسخ">نسخ</button>
  <button type="button" data-ayah-action="share" data-surah={surah} data-ayah={n} aria-label="مشاركة">مشاركة</button>
  <button type="button" data-ayah-action="bookmark" data-surah={surah} data-ayah={n} aria-label="حفظ" aria-pressed="false">حفظ</button>
  <button type="button" data-ayah-action="listen" data-surah={surah} data-ayah={n} aria-label="استمع">▶ استمع</button>
</div>
```
(needs `surah` prop added to AyahBlock: `interface Props { surah: number; n: number; ... }`; `[n].astro` passes it. Visible on `:focus-within`/hover; on `pointer:coarse` always visible with ≥44px targets.)
  - Page script (one `is:inline` module in `[n].astro`) wires: copy → `navigator.clipboard.writeText(textImlaei)` + button text feedback ("تم"); share → `shareOrCopy(surahUrl(s,a), textImlaei)`; bookmark → toggles + `aria-pressed` + label; listen → `qy:play` with the selected reciter row (from settings; fallback = first featured row fetched via `fetchReciters()` — cache rows on the page) + surah `s`.
  - Header: reciter `<select data-qy="reciter-pick">` populated from `fetchReciters()` (featured first, top ~10 + all option list), persisted `qy:reader.reciterRow`; play button dispatches `qy:play`.
  - Copy uses `i` — never `u` (PUA rule).
- [ ] **Step 3: e2e** (`ayah-actions.spec.ts`) with routed reciters fixture:
```ts
test('copy writes plain Arabic (not glyphs), share falls back to clipboard, bookmark persists', async ({ context, page }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.route('**/mp3quran.net/**', (r) => r.fulfill({ json: reciters2 }));
  await page.goto('/surah/1/');
  await page.locator('[data-ayah-action="copy"]').first().click();
  const clip = await page.evaluate(() => navigator.clipboard.readText());
  expect(clip).toContain('بسم');            // plain Arabic — proves not PUA
  expect(/[\uE000-\uF8FF]/.test(clip)).toBe(false);
  await page.locator('[data-ayah-action="share"]').first().click();
  const shared = await page.evaluate(() => navigator.clipboard.readText());
  expect(shared).toContain('/surah/1#ayah-1'); // Web Share blocked in headless → clipboard fallback
  await page.locator('[data-ayah-action="bookmark"]').nth(2).click();
  await page.reload();
  await expect(page.locator('[data-ayah-action="bookmark"]').nth(2)).toHaveAttribute('aria-pressed', 'true');
});
test('bookmark persists, listen dispatches the chosen reciter into the player', async ({ page }) => {
  await page.route('**/mp3quran.net/**', (r) => r.fulfill({ json: reciters2 }));
  await page.route('**/cdn.mp3quran.net/**', (r) => r.fulfill({ path: 'tests/fixtures/silent.wav', contentType: 'audio/wav' }));
  await page.goto('/surah/1/');
  await page.locator('[data-qy="reciter-pick"]').selectOption({ index: 0 });
  await page.locator('[data-ayah-action="listen"]').first().click();
  const bar = page.locator('[data-qy="bar"]');
  await expect(bar).toBeVisible();
  await expect(bar.locator('[data-qy="reciter"]')).not.toBeEmpty();
});
```
(Playwright headless without user activation may still allow clipboard with granted permissions; if `navigator.share` exists in the test browser, stub it: `await page.addInitScript(() => { Object.defineProperty(navigator, 'share', { value: undefined }); })` — documented in the spec file.)
- [ ] **Step 4: Gates**; [ ] **Step 5: Commit**

```bash
git add web/src/lib/bookmarks.ts web/src/lib/share.ts web/src/components/AyahBlock.astro web/src/pages/surah/[n].astro web/src/styles/global.css web/tests/unit/bookmarks.test.ts web/tests/unit/share.test.ts web/tests/e2e/ayah-actions.spec.ts
git commit -m "feat(web): per-ayah copy/share/bookmark/listen actions (i-text only)"
```

---

### Task 6: Full-text search (generator extension + client lib + /quran UI)

**Files:**
- Modify: `tools/export_web_data.dart` (add `search-index.json` output), `web/src/pages/quran.astro`, `web/src/components/SurahIndexFilter.tsx` (or new `SearchPanel.tsx`)
- Create (output): `web/src/data/search-index.json` (regenerated + committed)
- Create: `web/src/lib/search.ts`
- Test: extend `web/tests/unit/data.test.ts`, create `web/tests/unit/search.test.ts`, extend `web/tests/e2e/index.spec.ts`

**Interfaces:**
- Consumes: `normalizeArabic` (Task 4).
- Produces: `search-index.json` = `{"ayahs":[{"s":2,"a":255,"t":"…i-text…"}, …]}` (6236 records, `t` = Imlaei plain text); `search.ts`: `loadSearchIndex(): Promise<SearchRecord[]>` (fetch `/search-index.json`, module-cache), `searchAyahs(records, query, limit=50): Hit[]` where `Hit = {s:number; a:number; text:string}` ranked exact > word-prefix > contains, stable by (s,a).

- [ ] **Step 1: Dart generator extension** — inside the per-surah loop, collect `i` texts into `searchRows`, then after the totals check:

```dart
    File('${outDir.path}/search-index.json').writeAsStringSync(jsonEncode({
      'ayahs': searchRows,
    }));
```
with `final searchRows = <Map<String, Object?>>[];` and `searchRows.add({'s': s.id, 'a': a.numberInSurah, 't': a.textImlaei});` inside the ayah loop (skip empty `i`).
- [ ] **Step 2: Regenerate** — `dart run tools/export_web_data.dart` (expect OK line); sanity: `web/src/data/search-index.json` ≈ 600–900KB, 6236 entries (add asserts to `data.test.ts`: entries length 6236, 24:35 `t` contains «الله نور السماوات»).
- [ ] **Step 3: Failing search tests** — `search.test.ts`: ranking (exact ayah text beats contains), normalization parity («الرَّحْمَٰنِ الرَّحِيمِ»-style queries hit), limit respected, empty query → [].
- [ ] **Step 4: Implement `search.ts`** (fetch + normalize records lazily: normalize each `t` once on load into a parallel array; match on normalized, display raw `t`). Extend `/quran`: under the surah filter add an «بحث في الآيات» results section — first input ≥2 chars triggers `loadSearchIndex()` then renders ≤50 hits (`/surah/{s}#ayah-{a}` + snippet with the matching span emphasized). Keep the React island for the surah filter; the ayah-search panel is a vanilla island (small script) OR extend the React island — choose the React island extension (same page, no reader budget impact): add `useEffect` lazy-load of the index on first query ≥2 chars.
- [ ] **Step 5: e2e** — extend `index.spec.ts`: type «الله نور السماوات» → expect a result link `href="/surah/24#ayah-35"`; assert result count ≤50 (Fast: index fetch is local static).
- [ ] **Step 6: Gates; Commit**

```bash
git add tools/export_web_data.dart web/src/data/search-index.json web/src/lib/search.ts web/src/components/SurahIndexFilter.tsx web/src/pages/quran.astro web/tests/unit/data.test.ts web/tests/unit/search.test.ts web/tests/e2e/index.spec.ts
git commit -m "feat(web): full-text ayah search (generated index + ranked client search)"
```

---

### Task 7: Tafsir & translation panel (TDD-lite + routed e2e)

**Files:**
- Create: `web/src/lib/content-packs.ts`, `web/src/components/ContentPanel.astro`
- Modify: `web/src/pages/surah/[n].astro` (panel toggle + mount), `web/src/styles/global.css`, `web/src/lib/strings.ts`
- Create fixtures: `web/tests/fixtures/tafsir-1.json` (spa5k array shape), `web/tests/fixtures/translation-1.json` (fawazahmed `{chapter:[…]}` shape)
- Test: `web/tests/unit/content-packs.test.ts`, `web/tests/e2e/panel.spec.ts`

**Interfaces:**
- Produces: `PACKS: readonly PackInfo[]` where `PackInfo = { kind: 'tafsir' | 'translation'; id: string; titleAr: string; url(surah: number): string; parse(json: unknown): Map<number, string> }` for exactly these five (URLs verbatim; verified live 2026-10-18):
  - tafsir `ar-tafsir-muyassar`, `ar-tafsir-al-jalalayn` → `https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.2/tafsir/{id}/{surah}.json`, parse = array index+1
  - translation `ara-sirajtafseer`, `eng-safiurrahmanalm`, `eng-mustafakhattabg` → `https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/{id}/{surah}.json`, parse = `{chapter:[{verse,text}]}` → map verse→text
- `fetchPackAyahs(pack, surah): Promise<Map<number, string>>` (in-memory cache keyed `${kind}:${id}:${surah}`; on failure throw → UI shows localized error + retry button).
- Settings `qy:content` = `{ kind, id } | null`; DOM: header button `[data-qy="panel-toggle"]`, panel `#qy-content-panel` with per-ayah sub-blocks `.ayah-note[data-ayah="{n}"]`, attribution `.panel-source`.

- [ ] **Step 1: Unit tests** — `content-packs.test.ts`: URL builders exact for both shapes; parsers map the two fixture shapes to correct ayah→text; unknown/invalid JSON → throws.
- [ ] **Step 2: Component + wiring** — `ContentPanel.astro`: hidden by default; on toggle: `<select>` of the 5 packs + «إخفاء» — fetch for the current surah, render a `.ayah-note` under each ayah (appended into each `.ayah` via script), attribution line with `titleAr` + "المصدر: jsDelivr — {id}"; persisted selection; error banner with retry. Desktop: sticky side column ≥1100px (`grid` on `.reader`), mobile: stacked under each ayah (same DOM, CSS switches).
- [ ] **Step 3: e2e** (`panel.spec.ts`) — route `**/cdn.jsdelivr.net/**` → fixtures; open `/surah/1/`; toggle panel; pick «التفسير الميسر»; expect 7 `.ayah-note` with non-empty text; select «صحيح إنترناشيونال» → notes update (routed translation fixture); reload → selection persisted; route both to HTTP 500 → error banner + retry button visible.
- [ ] **Step 4: Gates; Commit**

```bash
git add web/src/lib/content-packs.ts web/src/components/ContentPanel.astro web/src/pages/surah/[n].astro web/src/styles/global.css web/src/lib/strings.ts web/tests/fixtures/tafsir-1.json web/tests/fixtures/translation-1.json web/tests/unit/content-packs.test.ts web/tests/e2e/panel.spec.ts
git commit -m "feat(web): tafsir & translation panel with curated packs (cached, routed e2e)"
```

---

### Task 8: `/reciters` browser — featured list, surah list, play + download

**Files:**
- Modify: `web/src/pages/reciters.astro` (build out from Task 3 stub), `web/src/components/Header.astro` (add التلاوات link — `navReciters` string exists), `web/src/styles/global.css`, `web/src/lib/strings.ts`
- Test: extend `web/tests/e2e/player.spec.ts` (or new `reciters.spec.ts`)

**Interfaces:**
- Consumes: `fetchReciters`, `sortReciters`, `isFeaturedRow`, `surahAudioUrl` (Task 1); `qy:play` event (Task 3).
- Produces: page contract `[data-reciter-row="{rowId}"]`, `[data-reciter-play]`, `[data-surah-row="{surah}"]`, download anchors `[data-surah-download]` (`href=surahAudioUrl`, `target="_blank"`, `rel="noopener"`).

- [ ] **Step 1: Implement** — server-rendered shell + vanilla script: `fetchReciters()` → render featured section (rows from featured ids in PM order, reciter + moshaf name chips) then «كل القراء» (collapsible, sorted); clicking a row expands its surah list (`surahList` or 1..114) with ▶ play (`qy:play` needs the full `MoshafRow` — store rows in a page-scoped map keyed by rowId) and «تحميل» anchor. Loading skeleton; error state → snapshot fallback is inside `fetchReciters` so the UI only sees rows; add localized empty/error strings.
- [ ] **Step 2: e2e** — routed reciters fixture (reuse `reciters-2.json` + extend to 3): assert featured order (51 first), expand surah list (3 surahs for the fixture row), click play → mini bar visible with that reciter name; download anchor href == expected `…/001.mp3` pattern; route API to 500 → page still lists the built-in snapshot's featured reciters (fallback proof).
- [ ] **Step 3: Gates; Commit**

```bash
git add web/src/pages/reciters.astro web/src/components/Header.astro web/src/styles/global.css web/src/lib/strings.ts web/tests/e2e/reciters.spec.ts web/tests/fixtures
git commit -m "feat(web): reciters browser with featured-first list, player dispatch and downloads"
```

---

### Task 9: Budget gates (reader JS + dist file count) as npm scripts

**Files:**
- Create: `web/scripts/check-budgets.mjs`
- Modify: `web/package.json` (scripts: `"budget": "node scripts/check-budgets.mjs"`, `"gates": "npm run check && npm run test && npm run build && npm run budget"`), `.github/workflows/web.yml` (append `npm run budget` step after build)

**Interfaces:**
- Produces: `npm run budget` — exits non-zero on: (a) `dist/surah/2/index.html` references any `/_astro/*.js` asset whose total gzip size > 30KB (should currently be ZERO referenced files — inline only); (b) any `dist/**` file count > 2000.

- [ ] **Step 1: Implement `check-budgets.mjs`** — read `dist/surah/2/index.html`, extract `src="/_astro/*.js"` refs; for each, gzip the file in memory (`node:zlib` gzipSync) and sum; read the html for INLINE script bytes as well and include them in the reported number; walk `dist` for file count; print a table; exit 1 with a clear message on breach:
```js
// Budgets (spec §5): reader ships ≤30KB gzip JS pre-interaction; dist < 2000 files.
```
- [ ] **Step 2: Run `npm run budget`** — expect PASS with the printed numbers (reader external refs: 0; inline scripts a few KB gzip; dist file count reported) — copy the output into the task report.
- [ ] **Step 3: Wire into `gates` + CI workflow**, run `npm run gates` end-to-end.
- [ ] **Step 4: Commit**

```bash
git add web/scripts/check-budgets.mjs web/package.json .github/workflows/web.yml
git commit -m "ci(web): reader JS + dist-count budget gate wired into gates and CI"
```

---

### Task 10: P2 close-out — docs truth-up + ledger

**Files:**
- Modify: `web/README.md` (feature list + new scripts), `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` (§7 P2 row → DONE + the client-normalization refinement note), `docs/campaign-ledger.md` (WEB-P2 close-out entry)
- Precondition: `git status --porcelain -- docs/campaign-ledger.md` EMPTY, else skip ledger + report.

- [ ] **Step 1: README** — features section: audio player + reciters, search, tafsir/translations, bookmarks, reader settings, a11y layer; scripts table adds `budget`.
- [ ] **Step 2: Spec §7** — mark the P2 row implemented on 2026-10-18 with the commit range; append the §3.5 refinement note (generator emits raw `i` records; normalization lives once in TS at `web/src/lib/arabic.ts`, client-side); append a W5 note: Tailwind v4 remains wired-but-unused through P2 (all styling is token CSS) — adopt-or-drop is a recorded owner decision for a later wave, and the spec stands as-is either way.
- [ ] **Step 3: Ledger** — WEB-P2 entry: scope, commits, gates evidence, deferred items receipt.
- [ ] **Step 4: Final gates** (`npm run gates && npm run test:e2e`) + `git add` the three docs + commit:

```bash
git commit -m "docs(web): p2 close-out — readme, spec status, ledger entry"
```

---

## Plan notes

- **Field-name parity:** all mp3quran parsing/sorting/trust rules mirror `lib/features/recitation/data/reciter_repository.dart` verbatim in intent; the pinned featured ids are copied from it — do not extend.
- **Per-ayah audio remains deferred** (needs an ayah-level source decision — P5 candidate). The per-ayah «استمع» opens the surah player (spec §3.6).
- **Resume/last-read:** Task 5 stores `qy:last-read {s, a}` on reader open; the visible «متابعة القراءة» strip ships with the P3 landing — storage is written now so P3 reads it without migration.
- **Superseded by `cebc8fc`:** `qy:last-read` storage deferred to P3 with its consumer (spec §7).
- **EN locale:** routes arrive P3; all new strings ship AR+EN pairs now (parity test enforces).
- **ClientRouter scope:** added to all pages (needed for the persistent player); reader inline JS stays ≤ budget; the `/quran` React island is unaffected.
- **e2e fixtures are the network contract:** every external host is routed; no live calls in CI.
