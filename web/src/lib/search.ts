import { normalizeArabic } from './arabic';
import {
  foldArabic,
  foldForm,
  matchSpan,
  rankAyahs,
  rankAyahsFolded,
  type Hit,
  type SearchRecord,
  type Span,
} from './search-core';

export { foldArabic, matchSpan, rankAyahs };
export type { Hit, SearchRecord, Span };

type WorkerReply =
  | { type: 'loaded'; records: SearchRecord[] }
  | { type: 'load-error'; message: string }
  | { type: 'hits'; id: number; hits: Hit[] }
  | { type: 'error'; id: number; message: string };

/**
 * The browser runs the search in a worker; the SSR build (and the unit tests,
 * which run in Node) has no worker, so it loads and ranks the index in-process.
 *
 * `import.meta.env.SSR` is a build-time constant and it is checked inline (not
 * through a helper), so the browser bundle folds the in-process path away - and
 * with it the index import only that path needs. The browser bundle then ships
 * the index to the worker alone.
 */

// --- Node fallback: the index is loaded and ranked in-process ---
let localRecords: SearchRecord[] | null = null;
let localNormalized: string[] = [];
let localFolded: string[] = [];
let localPending: Promise<SearchRecord[]> | null = null;

function loadLocalIndex(): Promise<SearchRecord[]> {
  localPending ??= import('../data/search-index.json')
    .then((mod) => {
      const ayahs = (mod as { default: { ayahs: SearchRecord[] } }).default.ayahs;
      localRecords = ayahs;
      localNormalized = ayahs.map((r) => normalizeArabic(r.t));
      localFolded = localNormalized.map(foldForm);
      return ayahs;
    })
    .catch((error: unknown) => {
      localPending = null;
      throw error;
    });
  return localPending;
}

// --- browser: the index and the ranking live in the worker ---
let worker: Worker | null = null;
let loadPending: Promise<SearchRecord[]> | null = null;
let loadResolve: ((records: SearchRecord[]) => void) | null = null;
let loadReject: ((error: unknown) => void) | null = null;
let nextQueryId = 0;
const pendingQueries = new Map<number, { resolve: (hits: Hit[]) => void; reject: (e: unknown) => void }>();
/** The hits the worker returned, keyed by query and limit. */
const hitCache = new Map<string, Hit[]>();

const cacheKey = (query: string, limit: number): string => `${query}\u0000${limit}`;

function killWorker(reason: unknown): void {
  const reject = loadReject;
  worker?.terminate();
  worker = null;
  loadPending = null;
  loadResolve = null;
  loadReject = null;
  for (const query of pendingQueries.values()) query.reject(reason);
  pendingQueries.clear();
  reject?.(reason);
}

function ensureWorker(): Worker {
  if (worker) return worker;
  const next = new Worker(new URL('./search-worker.ts', import.meta.url), { type: 'module' });
  next.addEventListener('message', (event: MessageEvent<WorkerReply>) => {
    const msg = event.data;
    if (msg.type === 'loaded') {
      loadResolve?.(msg.records);
      loadResolve = null;
      loadReject = null;
    } else if (msg.type === 'load-error') {
      killWorker(new Error(msg.message));
    } else if (msg.type === 'hits') {
      pendingQueries.get(msg.id)?.resolve(msg.hits);
      pendingQueries.delete(msg.id);
    } else if (msg.type === 'error') {
      pendingQueries.get(msg.id)?.reject(new Error(msg.message));
      pendingQueries.delete(msg.id);
    }
  });
  next.addEventListener('error', (event: ErrorEvent) => {
    killWorker(new Error(event.message || 'the search worker failed'));
  });
  worker = next;
  return next;
}

/**
 * Loads the committed index once and resolves with its records.
 *
 * In the browser the index is parsed and normalized inside the worker; in Node
 * (the unit tests) it is loaded in-process, because there is no worker there.
 */
export function loadSearchIndex(): Promise<SearchRecord[]> {
  if (import.meta.env.SSR) return loadLocalIndex();
  if (loadPending) return loadPending;
  loadPending = new Promise<SearchRecord[]>((resolve, reject) => {
    loadResolve = resolve;
    loadReject = reject;
    ensureWorker().postMessage({ type: 'load' });
  }).catch((error: unknown) => {
    loadPending = null;
    throw error;
  });
  return loadPending;
}

/**
 * The hits of a query, ranked in the worker.
 *
 * The worker owns the index, so the ranking cannot happen on this thread; the
 * result is cached here and `searchAyahs` reads it back synchronously.
 */
export function searchAyahsAsync(query: string, limit = 50): Promise<Hit[]> {
  if (import.meta.env.SSR) return Promise.resolve(searchAyahs(query, limit));
  const key = cacheKey(query, limit);
  const cached = hitCache.get(key);
  if (cached) return Promise.resolve(cached);
  return loadSearchIndex().then(
    () =>
      new Promise<Hit[]>((resolve, reject) => {
        const id = nextQueryId;
        nextQueryId += 1;
        pendingQueries.set(id, { resolve, reject });
        ensureWorker().postMessage({ type: 'query', id, query, limit });
      }),
  ).then((hits) => {
    hitCache.set(key, hits);
    return hits;
  });
}

/**
 * The hits of a query, from the last search that ran for it.
 *
 * In Node the index is ranked in-process. In the browser the ranking happens in
 * the worker, so this returns what `searchAyahsAsync` last computed for the
 * very same query and an empty list for a query that was never searched.
 */
export function searchAyahs(query: string, limit = 50): Hit[] {
  if (import.meta.env.SSR) {
    if (localRecords === null) return [];
    const normalizedQuery = normalizeArabic(query);
    if (!normalizedQuery) return [];
    return rankAyahsFolded(localRecords, localNormalized, localFolded, query, limit);
  }
  return hitCache.get(cacheKey(query, limit)) ?? [];
}
