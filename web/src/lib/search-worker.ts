/**
 * The verse search, off the UI thread.
 *
 * The committed indexes are ~854 KB (AR) and ~979 KB (EN) of JSON; parsing them
 * and normalizing their 6,236 records used to run on the main thread the moment
 * the user typed, and every query rescanned all 6,236 records. This worker owns
 * the whole job: it fetches the requested locale's index, builds the normalized
 * and alef-free forms once, and answers ranking queries.
 */
import { normalizeArabic } from './arabic';
import { foldForm, rankAyahsFolded, type SearchRecord } from './search-core';
// The indexes ship as hashed assets, so the worker downloads them as files and
// parses them here instead of the main thread parsing a bundled module.
import indexArUrl from '../data/search-index.json?url';
import indexEnUrl from '../data/search-index-en.json?url';

type SearchLocale = 'ar' | 'en';

type SearchRequest =
  | { type: 'load'; locale: SearchLocale }
  | { type: 'query'; id: number; query: string; limit: number; locale: SearchLocale };

/** The worker's own scope; the DOM lib types `self` as a Window. */
interface WorkerScope {
  postMessage(message: unknown): void;
  addEventListener(type: 'message', listener: (event: MessageEvent<SearchRequest>) => void): void;
}

const scope = self as unknown as WorkerScope;

interface LocaleIndex {
  url: string;
  records: SearchRecord[];
  normalized: string[];
  folded: string[];
  loading: Promise<void> | null;
}

const indexes: Record<SearchLocale, LocaleIndex> = {
  ar: { url: indexArUrl, records: [], normalized: [], folded: [], loading: null },
  en: { url: indexEnUrl, records: [], normalized: [], folded: [], loading: null },
};

function load(locale: SearchLocale): Promise<void> {
  const index = indexes[locale];
  index.loading ??= fetch(index.url, { credentials: 'omit' })
    .then((res) => {
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<{ ayahs: SearchRecord[] }>;
    })
    .then((data) => {
      index.records = data.ayahs;
      index.normalized = index.records.map((r) => normalizeArabic(r.t));
      index.folded = index.normalized.map(foldForm);
    });
  return index.loading;
}

scope.addEventListener('message', (event: MessageEvent<SearchRequest>) => {
  const msg = event.data;
  if (msg.type === 'load') {
    load(msg.locale).then(
      () =>
        scope.postMessage({
          type: 'loaded',
          locale: msg.locale,
          records: indexes[msg.locale].records,
        }),
      (error: unknown) =>
        scope.postMessage({ type: 'load-error', locale: msg.locale, message: String(error) }),
    );
    return;
  }
  const index = indexes[msg.locale];
  load(msg.locale).then(
    () =>
      scope.postMessage({
        type: 'hits',
        id: msg.id,
        hits: rankAyahsFolded(index.records, index.normalized, index.folded, msg.query, msg.limit),
      }),
    (error: unknown) => scope.postMessage({ type: 'error', id: msg.id, message: String(error) }),
  );
});
