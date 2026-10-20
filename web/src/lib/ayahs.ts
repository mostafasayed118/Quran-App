/**
 * The ayah text of one surah, as shipped in the generated src/data/ayahs/<id>.json.
 *
 * The dynamic import keeps the per-surah code splitting: every surah page pulls
 * only its own chunk, never all 114.
 */
export interface Ayah {
  n: number;
  juz: number;
  page: number;
  u: string;
  i: string;
  sajda: boolean;
}

export interface SurahAyahs {
  surah: number;
  ayahs: Ayah[];
}

/** The ayahs of one surah, loaded from the generated per-surah JSON. */
export async function getAyahs(surahId: number): Promise<SurahAyahs> {
  const mod = await import(`../data/ayahs/${surahId}.json`);
  return mod.default as SurahAyahs;
}
