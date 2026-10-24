import { describe, it, expect, beforeEach } from 'vitest';
import { createPlayer } from '../../src/lib/player';
import type { MoshafRow } from '../../src/lib/reciters';

class FakeAudio {
  src = '';
  currentTime = 0;
  duration = 0;
  paused = true;
  private listeners = new Map<string, Set<() => void>>();
  addEventListener(t: string, fn: () => void) {
    (this.listeners.get(t) ?? this.listeners.set(t, new Set()).get(t)!).add(fn);
  }
  removeEventListener(t: string, fn: () => void) {
    this.listeners.get(t)?.delete(fn);
  }
  emit(t: string) {
    this.listeners.get(t)?.forEach((fn) => fn());
  }
  play() {
    this.paused = false;
    this.emit('playing');
    return Promise.resolve();
  }
  pause() {
    this.paused = true;
    this.emit('pause');
  }
  load() {
    /* noop */
  }
}

const row: MoshafRow = {
  rowId: '51-5',
  reciterId: 51,
  reciterName: 'مشاري العفاسي',
  moshafId: 5,
  moshafName: 'حفص',
  server: 'https://cdn.mp3quran.net/a/afasy/r1/',
  surahList: [1, 2, 18],
  surahTotal: 3,
};

let audio: FakeAudio;
let urls: string[];
beforeEach(() => {
  audio = new FakeAudio();
  urls = [];
});

function make() {
  return createPlayer(audio as unknown as HTMLAudioElement, {
    urlFor: (r, s) => {
      urls.push(`${r.rowId}:${s}`);
      return `https://cdn.example/${s}.mp3`;
    },
  });
}

describe('player', () => {
  it('play() sets the url and reports loading→playing', async () => {
    const p = make();
    const seen: string[] = [];
    p.subscribe((s) => seen.push(s.status));
    p.play(row, 18);
    expect(audio.src).toBe('https://cdn.example/18.mp3');
    expect(urls).toEqual(['51-5:18']);
    await Promise.resolve();
    expect(seen[0]).toBe('loading');
    expect(p.state().status).toBe('playing');
  });
  it('next/prev cycle through the row surah list, wrapping', () => {
    const p = make();
    p.play(row, 2);
    p.next();
    expect(p.state().surah).toBe(18);
    p.next();
    expect(p.state().surah).toBe(1);
    p.prev();
    expect(p.state().surah).toBe(18);
  });
  it('toggle pauses and resumes without re-setting src', () => {
    const p = make();
    p.play(row, 1);
    audio.currentTime = 5;
    p.toggle();
    expect(audio.paused).toBe(true);
    p.toggle();
    expect(audio.paused).toBe(false);
    expect(audio.currentTime).toBe(5);
  });
  it('seekRatio clamps to [0,1] × duration', () => {
    const p = make();
    p.play(row, 1);
    audio.duration = 100;
    p.seekRatio(0.5);
    expect(audio.currentTime).toBe(50);
    p.seekRatio(2);
    expect(audio.currentTime).toBe(100);
  });
  it('audio error event lands in error state with the id retained', () => {
    const p = make();
    p.play(row, 1);
    audio.emit('error');
    expect(p.state().status).toBe('error');
    expect(p.state().surah).toBe(1);
  });
  it('falls back to 1..114 when surahList is empty', () => {
    const full = { ...row, surahList: [] as number[], surahTotal: 114 };
    const p = make();
    p.play(full, 114);
    p.next();
    expect(p.state().surah).toBe(1);
  });
});
