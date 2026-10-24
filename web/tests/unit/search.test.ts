import { describe, it, expect } from 'vitest';
import { normalizeArabic } from '../../src/lib/arabic';
import {
  foldArabic,
  loadSearchIndex,
  matchSpan,
  rankAyahs,
  searchAyahs,
  type SearchRecord,
} from '../../src/lib/search';

const fixture: SearchRecord[] = [
  { s: 5, a: 3, t: 'الله' },
  { s: 1, a: 1, t: 'بسم الله الرحمن الرحيم' },
  { s: 2, a: 255, t: 'الله لا اله الا هو الحي القيوم' },
  { s: 24, a: 35, t: 'الله نور السموات والارض' },
  { s: 55, a: 1, t: 'الرحمن' },
  { s: 112, a: 1, t: 'قل هو الله احد' },
  { s: 7, a: 1, t: 'منور' },
  { s: 8, a: 1, t: 'الرض' },
];
const norms = fixture.map((r) => normalizeArabic(r.t));
const ids = (hits: { s: number; a: number }[]) => hits.map((h) => `${h.s}:${h.a}`);

describe('searchAyahs before the index loads', () => {
  it('returns [] (no index, no results)', () => {
    expect(searchAyahs('الله')).toEqual([]);
  });
});

describe('rankAyahs', () => {
  it('empty or diacritics-only query returns []', () => {
    expect(rankAyahs(fixture, norms, '')).toEqual([]);
    expect(rankAyahs(fixture, norms, ' \u064B\u0652 ')).toEqual([]);
  });
  it('ranks whole-text exact before word-prefix before contains, stable by (s,a)', () => {
    expect(ids(rankAyahs(fixture, norms, 'الله'))).toEqual([
      '5:3',
      '1:1',
      '2:255',
      '24:35',
      '112:1',
    ]);
    expect(ids(rankAyahs(fixture, norms, 'الرحمن'))).toEqual(['55:1', '1:1']);
    expect(ids(rankAyahs(fixture, norms, 'حيم'))).toEqual(['1:1']);
  });
  it('word-prefix outranks mid-word contains', () => {
    expect(ids(rankAyahs(fixture, norms, 'نور'))).toEqual(['24:35', '7:1']);
  });
  it('normalization parity: diacritics/dagger-alef query matches plain text', () => {
    expect(ids(rankAyahs(fixture, norms, 'ٱلرَّحْمَٰنِ'))).toEqual(['55:1', '1:1']);
  });
  it('alef-tolerant fallback: typed «السماوات» finds rasm «السموات»', () => {
    expect(ids(rankAyahs(fixture, norms, 'السماوات'))).toEqual(['24:35']);
  });
  it('strict matches always rank before tolerant-only matches', () => {
    expect(ids(rankAyahs(fixture, norms, 'الارض'))).toEqual(['24:35', '8:1']);
  });
  it('respects the limit', () => {
    expect(rankAyahs(fixture, norms, 'الله', 2).map((h) => h.s)).toEqual([5, 1]);
  });
  it('returns display records {s,a,text} carrying the raw t', () => {
    const [hit] = rankAyahs(fixture, norms, 'السماوات');
    expect(hit).toEqual({ s: 24, a: 35, text: 'الله نور السموات والارض' });
  });
});

describe('loadSearchIndex / searchAyahs (real committed index)', () => {
  it('loads the committed index once and searches it', async () => {
    const records = await loadSearchIndex();
    expect(records).toHaveLength(6236);
    expect(await loadSearchIndex()).toBe(records); // module-level cache
    expect(ids(searchAyahs('الله نور السماوات'))).toContain('24:35');
    expect(searchAyahs('')).toEqual([]);
    expect(searchAyahs('الله', 3).length).toBeLessThanOrEqual(3);
  });
});

describe('matchSpan', () => {
  it('returns the raw span of a plain match', () => {
    const text = 'بسم الله الرحمن الرحيم';
    const span = matchSpan(text, 'الرحمن');
    expect(span).not.toBeNull();
    expect(text.slice(span!.start, span!.end)).toBe('الرحمن');
  });
  it('maps through diacritics back to the raw runes', () => {
    const text = 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
    const span = matchSpan(text, 'الرحمن');
    expect(span).not.toBeNull();
    expect(normalizeArabic(text.slice(span!.start, span!.end))).toBe('الرحمن');
  });
  it('marks the rasm run when the match is alef-tolerant', () => {
    const text = 'الله نور السموات والارض';
    const span = matchSpan(text, 'السماوات');
    expect(span).not.toBeNull();
    expect(text.slice(span!.start, span!.end)).toBe('السموات');
  });
  it('returns null when nothing matches', () => {
    expect(matchSpan('نص', 'زززز')).toBeNull();
  });
});

describe('foldArabic', () => {
  it('normalizes then drops alefs (spelling-agnostic matching spine)', () => {
    expect(foldArabic('السماوات')).toBe('لسموت');
    expect(foldArabic('  ٱلرَّحْمَٰنِ ')).toBe('لرحمن');
    expect(normalizeArabic('السموات')).toBe('السموات');
  });
});
