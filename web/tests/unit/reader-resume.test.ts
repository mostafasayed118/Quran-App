import { describe, it, expect } from 'vitest';
import { readResume, writeResume, RESUME_KEY } from '../../src/lib/reader-resume';

function fakeStorage() {
  const map = new Map<string, string>();
  return {
    getItem: (k: string) => (map.has(k) ? map.get(k)! : null),
    setItem: (k: string, v: string) => {
      map.set(k, String(v));
    },
  };
}

describe('reader resume (injected storage)', () => {
  it('roundtrips a resume point under qy:last-read', () => {
    const storage = fakeStorage();
    writeResume(storage, { s: 36, a: 5 });
    expect(JSON.parse(storage.getItem(RESUME_KEY)!)).toEqual({ s: 36, a: 5 });
    expect(readResume(storage)).toEqual({ s: 36, a: 5 });
  });

  it('reads null when the key is missing, corrupt or wrongly shaped', () => {
    expect(readResume(null)).toBeNull();
    const storage = fakeStorage();
    expect(readResume(storage)).toBeNull();
    storage.setItem(RESUME_KEY, 'not-json{');
    expect(readResume(storage)).toBeNull();
    storage.setItem(RESUME_KEY, 'null');
    expect(readResume(storage)).toBeNull();
    storage.setItem(RESUME_KEY, JSON.stringify([{ s: 2, a: 3 }]));
    expect(readResume(storage)).toBeNull();
    storage.setItem(RESUME_KEY, JSON.stringify({ s: 2 }));
    expect(readResume(storage)).toBeNull();
    storage.setItem(RESUME_KEY, JSON.stringify({ a: 3 }));
    expect(readResume(storage)).toBeNull();
  });

  it('rejects out-of-range surah ids', () => {
    const storage = fakeStorage();
    for (const s of [0, 115, '2', 2.5, -1, null]) {
      storage.setItem(RESUME_KEY, JSON.stringify({ s, a: 3 }));
      expect(readResume(storage)).toBeNull();
    }
    storage.setItem(RESUME_KEY, JSON.stringify({ s: 114, a: 1 }));
    expect(readResume(storage)).toEqual({ s: 114, a: 1 });
  });

  it('rejects non-integer or non-positive ayah numbers', () => {
    const storage = fakeStorage();
    for (const a of ['3', 1.5, 0, -2, null]) {
      storage.setItem(RESUME_KEY, JSON.stringify({ s: 2, a }));
      expect(readResume(storage)).toBeNull();
    }
  });

  it('write is a no-op with null storage and never throws on a throwing storage', () => {
    expect(() => writeResume(null, { s: 1, a: 1 })).not.toThrow();
    const throwing = {
      getItem: () => null,
      setItem: () => {
        throw new Error('quota');
      },
    };
    expect(() => writeResume(throwing, { s: 1, a: 1 })).not.toThrow();
  });
});
