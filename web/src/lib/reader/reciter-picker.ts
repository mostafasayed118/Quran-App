import { fetchReciters, fetchRecitersSnapshot, sortReciters, type MoshafRow } from '../reciters';
import { dedupeLabel } from '../labels';
import { PLAYER_EVENTS } from '../player';
import type { ReaderContext } from './context';

// Reciter rows are fetched once per page load and reused by the picker and the
// per-ayah listen actions. The cache lives at module scope so a ClientRouter
// swap does not refetch the reciters list.
let rowsPromise: Promise<MoshafRow[]> | null = null;
let resolvedRows: MoshafRow[] | null = null;

function loadRows(): Promise<MoshafRow[]> {
  rowsPromise ??= fetchReciters()
    .then((rows) => (resolvedRows = sortReciters(rows)))
    .catch(() => (resolvedRows = [] as MoshafRow[]));
  return rowsPromise;
}

export interface ReciterPicker {
  /** Plays the given surah with the reciter the picker is set to. */
  playSurah(surah: number): Promise<void>;
}

export function initReciterPicker(ctx: ReaderContext): ReciterPicker {
  const pick = document.querySelector<HTMLSelectElement>('[data-qy="reciter-pick"]');
  const playBtn = document.querySelector<HTMLButtonElement>('[data-qy="reader-play"]');

  const selectedRow = async (): Promise<MoshafRow | undefined> => {
    const wanted = pick?.value || ctx.settings().reciterRow;
    if (wanted) {
      const fromLive = resolvedRows?.find((r) => r.rowId === wanted);
      if (fromLive) return fromLive;
      const fromSnap = sortReciters(await fetchRecitersSnapshot()).find((r) => r.rowId === wanted);
      if (fromSnap) return fromSnap;
    }
    const rows = await loadRows();
    return rows.find((r) => r.rowId === wanted) ?? rows[0];
  };

  const playSurah = async (s: number): Promise<void> => {
    if (!Number.isFinite(s)) return;
    const row = await selectedRow();
    if (row) document.dispatchEvent(new CustomEvent(PLAYER_EVENTS.play, { detail: { row, surah: s } }));
  };

  if (pick) {
    loadRows().then((rows) => {
      pick.replaceChildren(
        ...rows.map((r) => {
          const opt = document.createElement('option');
          opt.value = r.rowId;
          opt.textContent = `${r.reciterName} — ${dedupeLabel(r.moshafName)}`;
          return opt;
        }),
      );
      const stored = ctx.settings().reciterRow;
      if (stored && rows.some((r) => r.rowId === stored)) pick.value = stored;
      pick.disabled = rows.length === 0;
    });
    pick.addEventListener('change', () => {
      ctx.saveSettings({ reciterRow: pick.value });
    });
  }
  playBtn?.addEventListener('click', () => {
    void playSurah(Number(playBtn.dataset.surah));
  });

  return { playSurah };
}
