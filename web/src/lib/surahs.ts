import surahsData from '../data/surahs.json';

/** One surah of the Mushaf, as shipped in the generated src/data/surahs.json. */
export interface Surah {
  id: number;
  nameAr: string;
  nameEn: string;
  revelationType: 'makkah' | 'medinan';
  ayahCount: number;
  pagesStart: number;
  pagesEnd: number;
}

const surahs: Surah[] = surahsData.surahs as Surah[];

/** The full surah index (114 surahs) in Mushaf order. */
export function getSurahs(): Surah[] {
  return surahs;
}
