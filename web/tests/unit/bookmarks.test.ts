import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  createBookmarkStore,
  isBookmarked,
  toggleBookmark,
  listBookmarks,
  BOOKMARKS_KEY,
} from '../../src/lib/bookmarks';

function fakeStorage(): Storage {
  const map = new Map<string, string>();
  return {
    get length() {
      return map.size;
    },
    clear: () => map.clear(),
    getItem: (k: string) => (map.has(k) ? map.get(k)! : null),
    key: (i: number) => Array.from(map.keys())[i] ?? null,
    removeItem: (k: string) => {
      map.delete(k);
    },
    setItem: (k: string, v: string) => {
      map.set(k, String(v));
    },
  } as Storage;
}

describe('bookmark store (injected storage)', () => {
  it('starts empty', () => {
    const store = createBookmarkStore(fakeStorage());
    expect(store.listBookmarks()).toEqual([]);
    expect(store.isBookmarked(1, 1)).toBe(false);
    expect(store.hitsFor(1)).toEqual([]);
  });

  it('toggle adds then removes and returns the NEW state', () => {
    const store = createBookmarkStore(fakeStorage());
    expect(store.toggleBookmark(1, 1)).toBe(true);
    expect(store.isBookmarked(1, 1)).toBe(true);
    expect(store.toggleBookmark(1, 1)).toBe(false);
    expect(store.isBookmarked(1, 1)).toBe(false);
    expect(store.listBookmarks()).toEqual([]);
  });

  it('persists as JSON under qy:bookmarks and survives a fresh store over the same storage', () => {
    const storage = fakeStorage();
    const store = createBookmarkStore(storage);
    store.toggleBookmark(2, 255);
    expect(JSON.parse(storage.getItem(BOOKMARKS_KEY)!)).toEqual([{ s: 2, a: 255 }]);
    const reopened = createBookmarkStore(storage);
    expect(reopened.isBookmarked(2, 255)).toBe(true);
    expect(reopened.listBookmarks()).toEqual([{ s: 2, a: 255 }]);
  });

  it('lists every bookmark in insertion order and hitsFor filters by surah', () => {
    const store = createBookmarkStore(fakeStorage());
    store.toggleBookmark(1, 1);
    store.toggleBookmark(1, 7);
    store.toggleBookmark(2, 1);
    expect(store.listBookmarks()).toEqual([
      { s: 1, a: 1 },
      { s: 1, a: 7 },
      { s: 2, a: 1 },
    ]);
    expect(store.hitsFor(1)).toEqual([1, 7]);
    expect(store.hitsFor(2)).toEqual([1]);
    expect(store.hitsFor(3)).toEqual([]);
  });

  it('clears to empty on invalid payloads and stays writable', () => {
    const storage = fakeStorage();
    const store = createBookmarkStore(storage);
    storage.setItem(BOOKMARKS_KEY, 'not-json{');
    expect(store.listBookmarks()).toEqual([]);
    expect(store.isBookmarked(1, 2)).toBe(false);
    storage.setItem(BOOKMARKS_KEY, JSON.stringify({ s: 1, a: 2 }));
    expect(store.listBookmarks()).toEqual([]);
    storage.setItem(BOOKMARKS_KEY, JSON.stringify([{ s: 'x', a: 1 }, { s: 2, a: 3 }]));
    expect(store.listBookmarks()).toEqual([{ s: 2, a: 3 }]);
    expect(store.toggleBookmark(1, 2)).toBe(true);
    expect(JSON.parse(storage.getItem(BOOKMARKS_KEY)!)).toEqual([{ s: 2, a: 3 }, { s: 1, a: 2 }]);
  });
});

describe('localStorage-bound helpers', () => {
  beforeEach(() => {
    vi.stubGlobal('localStorage', fakeStorage());
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('reads and writes through the global localStorage under qy:bookmarks', () => {
    expect(isBookmarked(3, 4)).toBe(false);
    expect(toggleBookmark(3, 4)).toBe(true);
    expect(isBookmarked(3, 4)).toBe(true);
    expect(listBookmarks()).toEqual([{ s: 3, a: 4 }]);
    expect(JSON.parse(localStorage.getItem('qy:bookmarks')!)).toEqual([{ s: 3, a: 4 }]);
  });
});
