export function surahNeighbors(n: number): { prev: number | null; next: number | null } {
  return { prev: n > 1 ? n - 1 : null, next: n < 114 ? n + 1 : null };
}
