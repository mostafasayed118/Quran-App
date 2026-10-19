import { normalizeArabic } from './arabic';

export interface SearchRecord {
  s: number;
  a: number;
  t: string;
}

export interface Hit {
  s: number;
  a: number;
  text: string;
}

export interface Span {
  start: number;
  end: number;
}

function stripAlef(normalized: string): string {
  return normalized.replace(/ا/g, '');
}

/**
 * Matching spine: normalizeArabic first, then drop alefs. The shipped DB
 * writes rasm-flavoured spellings («السموات») while typists use the standard
 * imlaei spelling («السماوات»); folding elsewhere would miss those verses.
 */
export function foldArabic(input: string): string {
  return stripAlef(normalizeArabic(input));
}

function rankIn(text: string, query: string): number | null {
  if (text === query) return 0;
  if (text.startsWith(query) || text.includes(` ${query}`)) return 1;
  if (text.includes(query)) return 2;
  return null;
}

function rankCore(
  records: readonly SearchRecord[],
  normalized: readonly string[],
  foldedForms: readonly string[] | null,
  query: string,
  limit: number,
): Hit[] {
  const foldedQuery = stripAlef(query);
  const scored: { rank: number; s: number; a: number; text: string }[] = [];
  for (let i = 0; i < records.length; i += 1) {
    let rank = rankIn(normalized[i], query);
    if (rank === null && foldedQuery) {
      const folded = rankIn(foldedForms ? foldedForms[i] : stripAlef(normalized[i]), foldedQuery);
      if (folded !== null) rank = folded + 3;
    }
    if (rank !== null) {
      scored.push({ rank, s: records[i].s, a: records[i].a, text: records[i].t });
    }
  }
  scored.sort((x, y) => x.rank - y.rank || x.s - y.s || x.a - y.a);
  return scored.slice(0, limit).map(({ s, a, text }) => ({ s, a, text }));
}

export function rankAyahs(
  records: readonly SearchRecord[],
  normalized: readonly string[],
  rawQuery: string,
  limit = 50,
): Hit[] {
  const query = normalizeArabic(rawQuery);
  if (!query) return [];
  return rankCore(records, normalized, null, query, limit);
}

let records: SearchRecord[] | null = null;
let normalized: string[] = [];
let foldedForms: string[] = [];
let pending: Promise<SearchRecord[]> | null = null;

/** Lazy-loads the committed index (code-split asset) once, then serves the module cache. */
export function loadSearchIndex(): Promise<SearchRecord[]> {
  pending ??= import('../data/search-index.json')
    .then((mod) => {
      const ayahs = (mod as { default: { ayahs: SearchRecord[] } }).default.ayahs;
      records = ayahs;
      normalized = ayahs.map((r) => normalizeArabic(r.t));
      foldedForms = normalized.map((f) => stripAlef(f));
      return ayahs;
    })
    .catch((error: unknown) => {
      pending = null;
      throw error;
    });
  return pending;
}

export function searchAyahs(query: string, limit = 50): Hit[] {
  if (records === null) return [];
  const normalizedQuery = normalizeArabic(query);
  if (!normalizedQuery) return [];
  return rankCore(records, normalized, foldedForms, normalizedQuery, limit);
}

function rawRange(
  rawText: string,
  foldLayer: boolean,
  start: number,
  length: number,
): Span | null {
  const endNorm = start + length;
  const last = rawText.length;
  // A sentinel keeps normalizeArabic's trim() from eating trailing spaces of a prefix.
  const mappedLength = (prefix: string): number => {
    const normalized = normalizeArabic(`${prefix}\u0000`);
    return (foldLayer ? stripAlef(normalized) : normalized).length - 1;
  };
  if (mappedLength(rawText) < endNorm) return null;
  const firstAt = (bound: number, strictlyGreater: boolean): number => {
    let lo = 0;
    let hi = last;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      const l = mappedLength(rawText.slice(0, mid));
      if (strictlyGreater ? l > bound : l >= bound) hi = mid;
      else lo = mid + 1;
    }
    return lo;
  };
  const end = firstAt(endNorm, false);
  let rawStart = firstAt(start, true) - 1;
  if (rawStart < 0 || end <= rawStart) return null;
  // Pull in leading chars that the layer dropped (e.g. the alef of «السموات»).
  while (
    rawStart > 0 &&
    mappedLength(rawText.slice(0, rawStart)) === mappedLength(rawText.slice(0, rawStart - 1))
  ) {
    rawStart -= 1;
  }
  return { start: rawStart, end };
}

/** Raw rune range of the match for <mark>, mapping normalized positions back to raw text. */
export function matchSpan(rawText: string, rawQuery: string): Span | null {
  const query = normalizeArabic(rawQuery);
  if (!query) return null;
  const normalizedText = normalizeArabic(rawText);
  const strictAt = normalizedText.indexOf(query);
  if (strictAt >= 0) {
    return rawRange(rawText, false, strictAt, query.length);
  }
  const foldedQuery = stripAlef(query);
  if (!foldedQuery) return null;
  const foldedAt = stripAlef(normalizedText).indexOf(foldedQuery);
  if (foldedAt < 0) return null;
  return rawRange(rawText, true, foldedAt, foldedQuery.length);
}
