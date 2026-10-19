/** PM-pinned featured reciters (parity with the app). Never extend without a grant. */
export const FEATURED_RECITER_IDS = [51, 123, 118, 92, 102, 54, 30, 4, 5] as const;

export interface MoshafRow {
  rowId: string;
  reciterId: number;
  reciterName: string;
  moshafId: number;
  moshafName: string;
  server: string;
  surahList: number[];
  surahTotal: number;
}

export function isTrustedAudioServer(server: string): boolean {
  let uri: URL;
  try { uri = new URL(server); } catch { return false; }
  return uri.protocol === 'https:' &&
    (uri.hostname === 'mp3quran.net' || uri.hostname.endsWith('.mp3quran.net'));
}

export function parseSurahList(csv: string): number[] {
  return csv.split(',').map((p) => Number.parseInt(p.trim(), 10)).filter((n) => Number.isFinite(n));
}

export function parseReciters(payload: unknown): MoshafRow[] {
  const reciters = (payload as { reciters?: unknown } | null)?.reciters;
  if (!Array.isArray(reciters)) return [];
  const rows: MoshafRow[] = [];
  for (const r of reciters) {
    if (typeof r !== 'object' || r === null) continue;
    const rec = r as Record<string, unknown>;
    if (typeof rec.id !== 'number' || !Array.isArray(rec.moshaf)) continue;
    for (const m of rec.moshaf) {
      if (typeof m !== 'object' || m === null) continue;
      const mo = m as Record<string, unknown>;
      if (typeof mo.id !== 'number') continue;
      if (typeof mo.server !== 'string' || !isTrustedAudioServer(mo.server)) continue;
      rows.push({
        rowId: `${rec.id}-${mo.id}`,
        reciterId: rec.id,
        reciterName: typeof rec.name === 'string' ? rec.name : '',
        moshafId: mo.id,
        moshafName: typeof mo.name === 'string' ? mo.name : '',
        server: mo.server,
        surahList: typeof mo.surah_list === 'string' ? parseSurahList(mo.surah_list) : [],
        surahTotal: typeof mo.surah_total === 'number' ? mo.surah_total : 0,
      });
    }
  }
  return rows;
}

export function isFeaturedRow(row: MoshafRow): boolean {
  return (FEATURED_RECITER_IDS as readonly number[]).includes(row.reciterId);
}

export function sortReciters(rows: MoshafRow[]): MoshafRow[] {
  const rank = new Map<number, number>(FEATURED_RECITER_IDS.map((id, i) => [id, i]));
  return [...rows].sort((a, b) => {
    const ra = rank.get(a.reciterId) ?? FEATURED_RECITER_IDS.length;
    const rb = rank.get(b.reciterId) ?? FEATURED_RECITER_IDS.length;
    if (ra !== rb) return ra - rb;
    const byName = a.reciterName.localeCompare(b.reciterName, 'ar');
    return byName !== 0 ? byName : a.rowId.localeCompare(b.rowId);
  });
}

export function surahAudioUrl(server: string, surah: number): string {
  const base = server.endsWith('/') ? server : `${server}/`;
  return `${base}${String(surah).padStart(3, '0')}.mp3`;
}

/** Live API with committed-snapshot fallback (spec §3.4). */
export async function fetchReciters(): Promise<MoshafRow[]> {
  try {
    const res = await fetch('https://mp3quran.net/api/v3/reciters?language=ar', { signal: AbortSignal.timeout(15000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const rows = parseReciters(await res.json());
    if (rows.length === 0) throw new Error('empty reciter payload');
    return rows;
  } catch {
    const { default: snapshot } = await import('../data/reciters-snapshot.json');
    return parseReciters(snapshot);
  }
}
