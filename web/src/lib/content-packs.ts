export type PackKind = 'translation';

export interface PackInfo {
  kind: PackKind;
  id: string;
  titleAr: string;
  /** The required attribution + pinned version shown in the panel source line. */
  attribution: string;
  url(surah: number): string;
  parse(json: unknown): Map<number, string>;
}

// fawazahmed0/quran-api per-surah payload: { chapter: [{ verse, text }, ...] }.
function parseTranslationChapter(json: unknown): Map<number, string> {
  const chapter =
    typeof json === 'object' && json !== null ? (json as { chapter?: unknown }).chapter : undefined;
  if (!Array.isArray(chapter)) throw new Error('invalid translation payload');
  const map = new Map<number, string>();
  for (const entry of chapter) {
    const item =
      typeof entry === 'object' && entry !== null
        ? (entry as { verse?: unknown; text?: unknown })
        : null;
    if (!item || typeof item.verse !== 'number' || typeof item.text !== 'string') {
      throw new Error('invalid translation entry');
    }
    map.set(item.verse, item.text);
  }
  if (map.size === 0) throw new Error('empty translation payload');
  return map;
}

// Pinned to the resolved COMMIT SHA of the edition (a tag is a mutable ref; the commit SHA is
// not). Parity with the app catalog, which pins the same SHA. The un-pin guard lives in
// tests/unit/content-packs.test.ts.
const FAWAZ_COMMIT = '47ca096b0976443ba2eab2e45cdf0fb4096a2610';
const FAWAZ_BASE = `https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@${FAWAZ_COMMIT}/editions`;

function translationPack(id: string, titleAr: string, attribution: string): PackInfo {
  return {
    kind: 'translation',
    id,
    titleAr,
    attribution,
    url: (surah) => `${FAWAZ_BASE}/${id}/${surah}.json`,
    parse: parseTranslationChapter,
  };
}

/**
 * Only the packs whose upstream terms allow redistribution on this free, ad-free site:
 *
 * - QuranEnc's At-Tafsir Al-Mukhtasar (Siraj): republished unmodified, attributed to
 *   QuranEnc.com with the pinned version.
 * - Pickthall's The Meaning of the Glorious Koran (1930): public domain (the translator died
 *   in 1936).
 *
 * The Quran Foundation tafsir packs and The Clear Quran were withdrawn on 2026-10-24 for
 * licensing reasons — do not re-add them without written permission.
 */
export const PACKS: readonly PackInfo[] = [
  translationPack(
    'ara-sirajtafseer',
    'المختصر في التفسير - سِراج',
    `QuranEnc.com · version ${FAWAZ_COMMIT}`,
  ),
  translationPack(
    'eng-mohammedmarmadu',
    'ترجمة بيكثال الإنجليزية',
    `fawazahmed0/quran-api · public domain · ${FAWAZ_COMMIT}`,
  ),
];

const cache = new Map<string, Map<number, string>>();

/** Rejects on failure (errors are never cached) so the caller can show error + retry. */
export async function fetchPackAyahs(pack: PackInfo, surah: number): Promise<Map<number, string>> {
  const key = `${pack.kind}:${pack.id}:${surah}`;
  const hit = cache.get(key);
  if (hit) return hit;
  const res = await fetch(pack.url(surah), { signal: AbortSignal.timeout(15000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const map = pack.parse(await res.json());
  cache.set(key, map);
  return map;
}
