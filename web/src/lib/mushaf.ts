export interface GroupedPage<T> {
  page: number;
  ayahs: T[];
}

export function groupAyahsByPage<T extends { n: number; page: number }>(
  ayahs: T[],
): GroupedPage<T>[] {
  const byPage = new Map<number, T[]>();
  for (const ayah of ayahs) {
    const list = byPage.get(ayah.page);
    if (list) list.push(ayah);
    else byPage.set(ayah.page, [ayah]);
  }
  return [...byPage.keys()]
    .sort((a, b) => a - b)
    .map((page) => ({
      page,
      ayahs: [...byPage.get(page)!].sort((a, b) => a.n - b.n),
    }));
}
