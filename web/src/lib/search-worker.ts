/**
 * The verse search, off the UI thread.
 *
 * The committed index is 837 KB of JSON; parsing it and normalizing its 6,236
 * records used to run on the main thread the moment the user typed, and every
 * query rescanned all 6,236 records. This worker owns the whole job: it fetches
 * the index, builds the normalized and alef-free forms once, and answers
 * ranking queries.
 */
import { normalizeArabic } from './arabic';
import { foldForm, rankAyahsFolded, type SearchRecord } from './search-core';
// The index ships as a hashed asset, so the worker downloads it as a file and
// parses it here instead of the main thread parsing a bundled module.
import indexUrl from '../data/search-index.json?url';

type SearchRequest =
  | { type: 'load' }
  | { type: 'query'; id: number; query: string; limit: number };

/** The worker's own scope; the DOM lib types `self` as a Window. */
interface WorkerScope {
  postMessage(message: unknown): void;
  addEventListener(type: 'message', listener: (event: MessageEvent<SearchRequest>) => void): void;
}

const scope = self as unknown as WorkerScope;

let records: SearchRecord[] = [];
let normalized: string[] = [];
let folded: string[] = [];
let loading: Promise<void> | null = null;

function load(): Promise<void> {
  loading ??= fetch(indexUrl, { credentials: 'omit' })
    .then((res) => {
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<{ ayahs: SearchRecord[] }>;
    })
    .then((data) => {
      records = data.ayahs;
      normalized = records.map((r) => normalizeArabic(r.t));
      folded = normalized.map(foldForm);
    });
  return loading;
}

scope.addEventListener('message', (event: MessageEvent<SearchRequest>) => {
  const msg = event.data;
  if (msg.type === 'load') {
    load().then(
      () => scope.postMessage({ type: 'loaded', records }),
      (error: unknown) => scope.postMessage({ type: 'load-error', message: String(error) }),
    );
    return;
  }
  load().then(
    () =>
      scope.postMessage({
        type: 'hits',
        id: msg.id,
        hits: rankAyahsFolded(records, normalized, folded, msg.query, msg.limit),
      }),
    (error: unknown) => scope.postMessage({ type: 'error', id: msg.id, message: String(error) }),
  );
});
