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

/** The locale of the index a query runs against. */
export type SearchLocale = 'ar' | 'en';

type WorkerReply =
  | { type: 'loaded'; locale: SearchLocale; records: SearchRecord[] }
  | { type: 'load-error'; locale: SearchLocale; message: string }
  | { type: 'hits'; id: number; hits: Hit[] }
  | { type: 'error'; id: number; message: string };

/**
 * The browser runs the search in a worker; the SSR build (and the unit tests,
 * which run in Node) has no worker, so it loads and ranks the requested
 * locale's index in-process.
 *
 * `import.meta.env.SSR` is a build-time constant and it is checked inline (not
 * through a helper), so the browser bundle folds the in-process path away - and
 * with it the index imports only that path needs. The browser bundle then ships
 * the indexes to the worker alone.
 */

// --- Node fallback: the requested locale's index is loaded and ranked in-process ---
interface LocalIndex {
  records: SearchRecord[] | null;
  normalized: string[];
  folded: string[];
  pending: Promise<SearchRecord[]> | null;
}

const localIndexes = new Map<SearchLocale, LocalIndex>();

function localIndex(locale: SearchLocale): LocalIndex {
  let state = localIndexes.get(locale);
  if (!state) {
    state = { records: null, normalized: [], folded: [], pending: null };
    localIndexes.set(locale, state);
  }
  return state;
}

function loadLocalIndex(locale: SearchLocale): Promise<SearchRecord[]> {
  const state = localIndex(locale);
  if (state.pending) return state.pending;
  const pending = (
    locale === 'en' ? import('../data/search-index-en.json') : import('../data/search-index.json')
  )
    .then((mod) => {
      const ayahs = (mod as { default: { ayahs: SearchRecord[] } }).default.ayahs;
      state.records = ayahs;
      state.normalized = ayahs.map((r) => normalizeArabic(r.t));
      state.folded = state.normalized.map(foldForm);
      return ayahs;
    })
    .catch((error: unknown) => {
      state.pending = null;
      throw error;
    });
  state.pending = pending;
  return pending;
}

// --- browser: the index and the ranking live in the worker ---
interface PendingLoad {
  promise: Promise<SearchRecord[]>;
  resolve: (records: SearchRecord[]) => void;
  reject: (error: unknown) => void;
}

let worker: Worker | null = null;
const pendingLoads = new Map<SearchLocale, PendingLoad>();
let nextQueryId = 0;
const pendingQueries = new Map<
  number,
  { resolve: (hits: Hit[]) => void; reject: (e: unknown) => void }
>();
/** The hits the worker returned, keyed by locale, query and limit. */
const hitCache = new Map<string, Hit[]>();

const cacheKey = (locale: SearchLocale, query: string, limit: number): string =>
  `${locale}\u0000${query}\u0000${limit}`;

function killWorker(reason: unknown): void {
  worker?.terminate();
  worker = null;
  const loads = [...pendingLoads.values()];
  pendingLoads.clear();
  for (const load of loads) load.reject(reason);
  for (const query of pendingQueries.values()) query.reject(reason);
  pendingQueries.clear();
}

function ensureWorker(): Worker {
  if (worker) return worker;
  const next = new Worker(new URL('./search-worker.ts', import.meta.url), { type: 'module' });
  next.addEventListener('message', (event: MessageEvent<WorkerReply>) => {
    const msg = event.data;
    if (msg.type === 'loaded') {
      // Keep the resolved promise: later callers reuse the same records instead
      // of asking the worker to load the locale again (the old AR-only behavior).
      pendingLoads.get(msg.locale)?.resolve(msg.records);
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
 * Loads a locale's committed index once and resolves with its records.
 *
 * In the browser the index is parsed and normalized inside the worker; in Node
 * (the unit tests) it is loaded in-process, because there is no worker there.
 * The default locale keeps the existing AR-only call sites working.
 */
export function loadSearchIndex(locale: SearchLocale = 'ar'): Promise<SearchRecord[]> {
  if (import.meta.env.SSR) return loadLocalIndex(locale);
  const pending = pendingLoads.get(locale);
  if (pending) return pending.promise;
  let resolve!: (records: SearchRecord[]) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<SearchRecord[]>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  pendingLoads.set(locale, { promise, resolve, reject });
  ensureWorker().postMessage({ type: 'load', locale });
  return promise;
}

/**
 * The hits of a query, ranked in the worker against the requested locale's index.
 *
 * The worker owns the indexes, so the ranking cannot happen on this thread; the
 * result is cached here and `searchAyahs` reads it back synchronously.
 */
export function searchAyahsAsync(
  query: string,
  limit = 50,
  locale: SearchLocale = 'ar',
): Promise<Hit[]> {
  if (import.meta.env.SSR) return Promise.resolve(searchAyahs(query, limit, locale));
  const key = cacheKey(locale, query, limit);
  const cached = hitCache.get(key);
  if (cached) return Promise.resolve(cached);
  return loadSearchIndex(locale)
    .then(
      () =>
        new Promise<Hit[]>((resolve, reject) => {
          const id = nextQueryId;
          nextQueryId += 1;
          pendingQueries.set(id, { resolve, reject });
          ensureWorker().postMessage({ type: 'query', id, query, limit, locale });
        }),
    )
    .then((hits) => {
      hitCache.set(key, hits);
      return hits;
    });
}

/**
 * The hits of a query, from the last search that ran for it.
 *
 * In Node the index is ranked in-process. In the browser the ranking happens in
 * the worker, so this returns what `searchAyahsAsync` last computed for the
 * very same locale, query and limit, and an empty list for a query that was
 * never searched.
 */
export function searchAyahs(query: string, limit = 50, locale: SearchLocale = 'ar'): Hit[] {
  if (import.meta.env.SSR) {
    const state = localIndex(locale);
    const records = state.records;
    if (records === null) return [];
    const normalizedQuery = normalizeArabic(query);
    if (!normalizedQuery) return [];
    return rankAyahsFolded(records, state.normalized, state.folded, query, limit);
  }
  return hitCache.get(cacheKey(locale, query, limit)) ?? [];
}
