/**
 * The English translation of one surah, as shipped in the generated
 * src/data/translation-en/<id>.json.
 *
 * The dynamic import keeps the per-surah code splitting: every surah page pulls
 * only its own chunk, never all 114.
 */
export interface TranslationAyah {
  n: number;
  t: string;
}

export interface SurahTranslation {
  surah: number;
  ayahs: TranslationAyah[];
}

/** Ayah number → English text for one surah, loaded from the generated per-surah JSON. */
export async function getTranslation(surahId: number): Promise<Map<number, string>> {
  const mod = await import(`../data/translation-en/${surahId}.json`);
  const data = mod.default as SurahTranslation;
  return new Map(data.ayahs.map((a) => [a.n, a.t]));
}
