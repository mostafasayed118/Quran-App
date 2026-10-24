import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  readReaderSettings,
  writeReaderSettings,
  READER_DEFAULTS,
} from '../../src/lib/reader-settings';

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

beforeEach(() => {
  vi.stubGlobal('localStorage', fakeStorage());
});
afterEach(() => {
  vi.unstubAllGlobals();
});

describe('reader settings', () => {
  it('defaults to fontStep 0 / mushaf / no reciter row when nothing is stored', () => {
    expect(READER_DEFAULTS).toEqual({ fontStep: 0, view: 'mushaf', reciterRow: '' });
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'mushaf', reciterRow: '' });
  });
  it('round-trips through JSON under the qy:reader key', () => {
    expect(writeReaderSettings({ view: 'imlaei' })).toEqual({
      fontStep: 0,
      view: 'imlaei',
      reciterRow: '',
    });
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'imlaei', reciterRow: '' });
    expect(JSON.parse(localStorage.getItem('qy:reader')!)).toEqual({
      fontStep: 0,
      view: 'imlaei',
      reciterRow: '',
    });
    expect(writeReaderSettings({ fontStep: 3 })).toEqual({
      fontStep: 3,
      view: 'imlaei',
      reciterRow: '',
    });
    expect(readReaderSettings()).toEqual({ fontStep: 3, view: 'imlaei', reciterRow: '' });
    expect(writeReaderSettings({ reciterRow: '51-1' })).toEqual({
      fontStep: 3,
      view: 'imlaei',
      reciterRow: '51-1',
    });
    expect(readReaderSettings()).toEqual({ fontStep: 3, view: 'imlaei', reciterRow: '51-1' });
  });
  it('falls back to defaults on invalid payloads', () => {
    localStorage.setItem('qy:reader', 'not-json{');
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'mushaf', reciterRow: '' });
    localStorage.setItem('qy:reader', JSON.stringify({ fontStep: 9, view: 'wide' }));
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'mushaf', reciterRow: '' });
    localStorage.setItem('qy:reader', JSON.stringify(null));
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'mushaf', reciterRow: '' });
  });
  it('keeps the valid fields of a partial payload', () => {
    localStorage.setItem('qy:reader', JSON.stringify({ fontStep: 2 }));
    expect(readReaderSettings()).toEqual({ fontStep: 2, view: 'mushaf', reciterRow: '' });
    localStorage.setItem('qy:reader', JSON.stringify({ view: 'imlaei', fontStep: '1' }));
    expect(readReaderSettings()).toEqual({ fontStep: 0, view: 'imlaei', reciterRow: '' });
  });
});
