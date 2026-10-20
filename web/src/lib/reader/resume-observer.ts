import { writeResume } from '../reader-resume';
import type { ReaderContext } from './context';

export interface ResumeObserver {
  /** True when this page has a surah and ayah blocks worth tracking. */
  readonly active: boolean;
  /** Starts tracking the topmost visible ayah. */
  start(): void;
  /** Stops tracking and drops the pending flush. */
  stop(): void;
}

/** True when the page can track a resume point: a surah and at least one ayah. */
export function canTrackResume(surahId: number, ayahCount: number): boolean {
  return Number.isInteger(surahId) && ayahCount > 0;
}

/**
 * The ayah the resume point follows: the first ayah of the list that is on
 * screen. Null when nothing is visible (or the ayah number is unusable).
 */
export function firstVisibleAyah(
  blocks: readonly { n: number }[],
  visible: ReadonlySet<number>,
): number | null {
  for (const block of blocks) {
    if (!visible.has(block.n)) continue;
    return Number.isInteger(block.n) ? block.n : null;
  }
  return null;
}

export function initResumeObserver(ctx: ReaderContext): ResumeObserver {
  // --- resume point: qy:last-read keeps the topmost visible ayah (throttled ~1s; verses mode) ---
  const blocks = Array.from(ctx.ayahs?.querySelectorAll<HTMLElement>('.ayah') ?? []);
  const ayahNumbers = blocks.map((el) => ({ n: Number(el.dataset.n) }));
  const active = canTrackResume(ctx.surahId, blocks.length);
  const visible = new Set<number>();
  let observer: IntersectionObserver | null = null;
  let flushTimer = 0;

  const stop = (): void => {
    window.clearTimeout(flushTimer);
    flushTimer = 0;
    observer?.disconnect();
    observer = null;
  };

  const flush = (): void => {
    flushTimer = 0;
    if (!ctx.box.isConnected) return; // a ClientRouter swap already moved on
    const a = firstVisibleAyah(ayahNumbers, visible);
    if (a !== null) writeResume(localStorage, { s: ctx.surahId, a });
  };

  const start = (): void => {
    if (!active) return;
    stop();
    const next = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        const n = Number((entry.target as HTMLElement).dataset.n);
        if (entry.isIntersecting) visible.add(n);
        else visible.delete(n);
      }
      if (flushTimer === 0) flushTimer = window.setTimeout(flush, 1000);
    });
    for (const el of blocks) next.observe(el);
    observer = next;
  };

  return { active, start, stop };
}
