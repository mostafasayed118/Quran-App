import { normalizeArabic } from './arabic';

export function normalizeQuery(q: string): string {
  return normalizeArabic(q);
}

export interface SurahLike { id: number; nameAr: string; nameEn: string }

export function filterSurahs<T extends SurahLike>(list: T[], q: string): T[] {
  const n = normalizeQuery(q);
  if (!n) return list;
  const asNum = /^\d+$/.test(n) ? Number(n) : null;
  const scored = list
    .map((s) => {
      const ar = normalizeQuery(s.nameAr);
      const en = s.nameEn.toLowerCase();
      if (asNum !== null && s.id === asNum) return { s, rank: 0 };
      if (ar === n || en === n) return { s, rank: 0 };
      if (ar.startsWith(n) || en.startsWith(n)) return { s, rank: 1 };
      if (ar.includes(n) || en.includes(n)) return { s, rank: 2 };
      return null;
    })
    .filter((x): x is { s: T; rank: number } => x !== null)
    .sort((a, b) => a.rank - b.rank || a.s.id - b.s.id);
  return scored.map((x) => x.s);
}
