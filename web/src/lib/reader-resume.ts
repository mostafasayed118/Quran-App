export const RESUME_KEY = 'qy:last-read';

export type ResumePoint = { s: number; a: number };

type StorageLike = Pick<Storage, 'getItem' | 'setItem'>;

function isIndex(x: unknown): x is number {
  return typeof x === 'number' && Number.isInteger(x);
}

export function readResume(storage: StorageLike | null): ResumePoint | null {
  if (storage === null) return null;
  const raw = storage.getItem(RESUME_KEY);
  if (raw === null) return null;
  try {
    const parsed: unknown = JSON.parse(raw);
    if (typeof parsed !== 'object' || parsed === null) return null;
    const { s, a } = parsed as { s?: unknown; a?: unknown };
    if (!isIndex(s) || s < 1 || s > 114) return null;
    if (!isIndex(a) || a < 1) return null;
    return { s, a };
  } catch {
    return null;
  }
}

export function writeResume(storage: StorageLike | null, p: ResumePoint): void {
  if (storage === null) return;
  try {
    storage.setItem(RESUME_KEY, JSON.stringify(p));
  } catch {
    /* private mode — nothing more we can do */
  }
}
