import { describe, it, expect } from 'vitest';
import {
  parseReciters, sortReciters, isTrustedAudioServer, surahAudioUrl, isFeaturedRow, dedupeLabel,
  FEATURED_RECITER_IDS, type MoshafRow,
} from '../../src/lib/reciters';
import snapshot from '../../src/data/reciters-snapshot.json';

const good = {
  reciters: [
    { id: 999, name: 'زمزم', letter: 'ز', date: 'x', moshaf: [{ id: 1, name: 'حفص', rewaya_id: 1, server: 'https://cdn.mp3quran.net/a/zamzam/r1/', surah_total: 3, moshaf_type: 11, surah_list: '1,2,3' }] },
    { id: 51, name: 'مشاري العفاسي', letter: 'م', date: 'x', moshaf: [{ id: 5, name: 'حفص عن عاصم - مرتل', rewaya_id: 1, server: 'https://cdn.mp3quran.net/a/afasy/r1/', surah_total: 114, moshaf_type: 11, surah_list: '' }] },
    { id: 7, name: 'شرير', letter: 'ش', date: 'x', moshaf: [{ id: 2, name: 'http خبيث', rewaya_id: 1, server: 'http://evil.example.com/e/', surah_total: 114, moshaf_type: 11, surah_list: '' }] },
    { id: 'bad' },
  ],
};

describe('parseReciters', () => {
  it('drops malformed reciters and untrusted servers', () => {
    const rows = parseReciters(good);
    expect(rows).toHaveLength(2);
    expect(rows.every((r) => r.server.startsWith('https://'))).toBe(true);
  });
  it('parses surah_list CSV and keeps totals', () => {
    const rows = parseReciters(good);
    const zam = rows.find((r) => r.reciterId === 999)!;
    expect(zam.surahList).toEqual([1, 2, 3]);
    expect(zam.rowId).toBe('999-1');
    expect(zam.surahTotal).toBe(3);
  });
  it('tolerates junk hosts and non-object payloads', () => {
    expect(parseReciters(null)).toEqual([]);
    expect(parseReciters({ reciters: 'nope' })).toEqual([]);
    expect(isTrustedAudioServer('https://notmp3quran.net/x/')).toBe(false);
    expect(isTrustedAudioServer('https://cdn.mp3quran.net/x/')).toBe(true);
    expect(isTrustedAudioServer('https://mp3quran.net/x/')).toBe(true);
  });
});

describe('sortReciters', () => {
  it('ranks featured ids first (PM order), then by name, then id', () => {
    const rows: MoshafRow[] = [
      { rowId: '999-1', reciterId: 999, reciterName: 'زمزم', moshafId: 1, moshafName: '', server: 'https://cdn.mp3quran.net/z/', surahList: [], surahTotal: 114 },
      { rowId: '51-5', reciterId: 51, reciterName: 'مشاري العفاسي', moshafId: 5, moshafName: '', server: 'https://cdn.mp3quran.net/a/', surahList: [], surahTotal: 114 },
      { rowId: '123-1', reciterId: 123, reciterName: 'ياسر الدوسري', moshafId: 1, moshafName: '', server: 'https://cdn.mp3quran.net/y/', surahList: [], surahTotal: 114 },
    ];
    const sorted = sortReciters(rows);
    expect(sorted.map((r) => r.reciterId)).toEqual([51, 123, 999]);
    expect(isFeaturedRow(sorted[0])).toBe(true);
    expect(isFeaturedRow(sorted[2])).toBe(false);
    expect(FEATURED_RECITER_IDS[0]).toBe(51);
  });
});

describe('surahAudioUrl', () => {
  it('pads to 3 digits and normalizes the trailing slash', () => {
    expect(surahAudioUrl('https://cdn.mp3quran.net/a/r1/', 1)).toBe('https://cdn.mp3quran.net/a/r1/001.mp3');
    expect(surahAudioUrl('https://cdn.mp3quran.net/a/r1', 114)).toBe('https://cdn.mp3quran.net/a/r1/114.mp3');
  });
});

describe('dedupeLabel', () => {
  it('collapses a byte-equal "X - X" duplicate (real upstream shape)', () => {
    expect(dedupeLabel('المصحف المجود - المصحف المجود')).toBe('المصحف المجود');
    expect(dedupeLabel('المصحف المعلم - المصحف المعلم')).toBe('المصحف المعلم');
  });
  it('trims around the separator before comparing', () => {
    expect(dedupeLabel('حفص  -  حفص ')).toBe('حفص');
  });
  it('keeps labels whose two sides differ', () => {
    expect(dedupeLabel('حفص عن عاصم - مرتل')).toBe('حفص عن عاصم - مرتل');
    expect(dedupeLabel('A - A - A')).toBe('A - A - A');
  });
  it('keeps labels without a separator untouched', () => {
    expect(dedupeLabel('حفص')).toBe('حفص');
    expect(dedupeLabel('')).toBe('');
    expect(dedupeLabel(' - ')).toBe(' - ');
  });
});

describe('committed snapshot', () => {
  it('is parseable and contains the featured reciters', () => {
    const rows = parseReciters(snapshot);
    expect(rows.length).toBeGreaterThan(50);
    for (const id of FEATURED_RECITER_IDS) {
      expect(rows.some((r) => r.reciterId === id), `featured ${id} in snapshot`).toBe(true);
    }
  });
});
