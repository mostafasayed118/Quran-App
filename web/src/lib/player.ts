import { surahAudioUrl, type MoshafRow } from './reciters';
import { writeSetting } from './settings';

export interface PlayerState {
  row: MoshafRow | null;
  surah: number | null;
  status: 'idle' | 'loading' | 'playing' | 'paused' | 'error';
  currentTime: number;
  duration: number;
}

export interface Player {
  play(row: MoshafRow, surah: number): void;
  toggle(): void;
  seekRatio(r: number): void;
  next(): void;
  prev(): void;
  state(): PlayerState;
  subscribe(fn: (s: PlayerState) => void): () => void;
}

function surahsFor(row: MoshafRow): number[] {
  return row.surahList.length > 0 ? row.surahList : Array.from({ length: 114 }, (_, i) => i + 1);
}

export function createPlayer(
  audio: HTMLAudioElement,
  deps: { urlFor?: (row: MoshafRow, surah: number) => string } = {},
): Player {
  const urlFor = deps.urlFor ?? ((row, surah) => surahAudioUrl(row.server, surah));
  const listeners = new Set<(s: PlayerState) => void>();
  let state: PlayerState = { row: null, surah: null, status: 'idle', currentTime: 0, duration: 0 };

  const emit = () => listeners.forEach((fn) => fn(state));
  const set = (patch: Partial<PlayerState>) => { state = { ...state, ...patch }; emit(); };

  audio.addEventListener('playing', () => set({ status: 'playing' }));
  audio.addEventListener('pause', () => { if (state.status !== 'idle') set({ status: 'paused' }); });
  audio.addEventListener('timeupdate', () => set({ currentTime: audio.currentTime }));
  audio.addEventListener('loadedmetadata', () => set({ duration: audio.duration }));
  audio.addEventListener('error', () => { if (state.surah !== null) set({ status: 'error' }); });

  function load(row: MoshafRow, surah: number) {
    set({ row, surah, status: 'loading', currentTime: 0, duration: 0 });
    // Written for a possible shell-restore; no reader yet — see campaign ledger.
    writeSetting('player:row', row.rowId);
    writeSetting('player:surah', surah);
    audio.src = urlFor(row, surah);
    audio.load();
    void audio.play().catch(() => { /* autoplay/abort — error event covers real failures */ });
  }

  return {
    play(row, surah) { load(row, surah); },
    toggle() { if (audio.paused) void audio.play().catch(() => {}); else audio.pause(); },
    seekRatio(r) { if (audio.duration > 0) audio.currentTime = Math.min(Math.max(r, 0), 1) * audio.duration; },
    next() {
      if (!state.row || state.surah === null) return;
      const list = surahsFor(state.row);
      const i = list.indexOf(state.surah);
      load(state.row, list[(i + 1) % list.length]);
    },
    prev() {
      if (!state.row || state.surah === null) return;
      const list = surahsFor(state.row);
      const i = list.indexOf(state.surah);
      load(state.row, list[(i - 1 + list.length) % list.length]);
    },
    state: () => state,
    subscribe(fn) { listeners.add(fn); return () => listeners.delete(fn); },
  };
}

let singleton: Player | null = null;
export function getPlayer(): Player {
  if (singleton) return singleton;
  const audio = document.getElementById('qy-audio') as HTMLAudioElement | null;
  if (!audio) throw new Error('qy-audio element missing');
  singleton = createPlayer(audio);
  return singleton;
}
