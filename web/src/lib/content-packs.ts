export type PackKind = 'tafsir' | 'translation';

export interface PackInfo {
  kind: PackKind;
  id: string;
  titleAr: string;
  url(surah: number): string;
  parse(json: unknown): Map<number, string>;
}

// spa5k/tafsir_api per-surah payload: [{ text }, ...] indexed by ayah-1.
function parseTafsirArray(json: unknown): Map<number, string> {
  if (!Array.isArray(json)) throw new Error('invalid tafsir payload');
  const map = new Map<number, string>();
  json.forEach((entry, i) => {
    const text =
      typeof entry === 'object' && entry !== null ? (entry as { text?: unknown }).text : undefined;
    if (typeof text !== 'string') throw new Error(`invalid tafsir entry ${i + 1}`);
    map.set(i + 1, text);
  });
  if (map.size === 0) throw new Error('empty tafsir payload');
  return map;
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

// Pinned to the resolved COMMIT SHA of the v1.2.2 tag (a tag is a mutable ref; the commit SHA is not).
// Parity with the app catalog, which pins the same SHA. Never move it back to a tag or to @1.
// The pin is the integrity boundary; a SHA-256 manifest was evaluated and SKIPPED (owner-approved 2026-10-19) — it would be a
// network-dependent CI check for marginal gain over an immutable URL. The un-pin guard lives in tests/unit/content-packs.test.ts.
const SPA5K_BASE =
  'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@eb82bb6294efe30ad5c135c03b1864afaa70e855/tafsir';
const FAWAZ_BASE =
  'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@47ca096b0976443ba2eab2e45cdf0fb4096a2610/editions';

function tafsirPack(id: string, titleAr: string): PackInfo {
  return {
    kind: 'tafsir',
    id,
    titleAr,
    url: (surah) => `${SPA5K_BASE}/${id}/${surah}.json`,
    parse: parseTafsirArray,
  };
}

function translationPack(id: string, titleAr: string): PackInfo {
  return {
    kind: 'translation',
    id,
    titleAr,
    url: (surah) => `${FAWAZ_BASE}/${id}/${surah}.json`,
    parse: parseTranslationChapter,
  };
}

/** PM-curated packs (URLs verified live 2026-10-18). Never extend without a grant. */
export const PACKS: readonly PackInfo[] = [
  tafsirPack('ar-tafsir-muyassar', 'التفسير الميسر'),
  tafsirPack('ar-tafsir-al-jalalayn', 'تفسير الجلالين'),
  translationPack('ara-sirajtafseer', 'المختصر في التفسير - سِراج'),
  translationPack('eng-safiurrahmanalm', 'صحيح إنترناشيونال'),
  translationPack('eng-mustafakhattabg', 'The Clear Quran'),
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
