export const BOOKMARKS_KEY = 'qy:bookmarks';

export interface Bookmark {
  s: number;
  a: number;
}

export interface BookmarkStore {
  isBookmarked(s: number, a: number): boolean;
  toggleBookmark(s: number, a: number): boolean;
  listBookmarks(): Bookmark[];
  hitsFor(s: number): number[];
}

type StorageLike = Pick<Storage, 'getItem' | 'setItem'>;

function isIndex(x: unknown): x is number {
  return typeof x === 'number' && Number.isInteger(x);
}

function coerce(raw: string | null): Bookmark[] {
  if (raw === null) return [];
  try {
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    const out: Bookmark[] = [];
    for (const entry of parsed) {
      if (typeof entry !== 'object' || entry === null) continue;
      const { s, a } = entry as { s?: unknown; a?: unknown };
      if (isIndex(s) && isIndex(a)) out.push({ s, a });
    }
    return out;
  } catch {
    return [];
  }
}

export function createBookmarkStore(storage: StorageLike): BookmarkStore {
  const read = (): Bookmark[] => coerce(storage.getItem(BOOKMARKS_KEY));
  const write = (list: Bookmark[]): void => {
    try {
      storage.setItem(BOOKMARKS_KEY, JSON.stringify(list));
    } catch {
      /* private mode — nothing more we can do */
    }
  };
  return {
    isBookmarked(s, a) {
      return read().some((b) => b.s === s && b.a === a);
    },
    toggleBookmark(s, a) {
      const list = read();
      const i = list.findIndex((b) => b.s === s && b.a === a);
      if (i >= 0) list.splice(i, 1);
      else list.push({ s, a });
      write(list);
      return read().some((b) => b.s === s && b.a === a);
    },
    listBookmarks() {
      return read();
    },
    hitsFor(s) {
      return read()
        .filter((b) => b.s === s)
        .map((b) => b.a);
    },
  };
}

export function isBookmarked(s: number, a: number): boolean {
  return createBookmarkStore(localStorage).isBookmarked(s, a);
}

export function toggleBookmark(s: number, a: number): boolean {
  return createBookmarkStore(localStorage).toggleBookmark(s, a);
}

export function listBookmarks(): Bookmark[] {
  return createBookmarkStore(localStorage).listBookmarks();
}
