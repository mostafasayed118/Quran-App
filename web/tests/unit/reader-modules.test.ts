import { describe, it, expect } from 'vitest';
import { groupAyahsByPage } from '../../src/lib/reader/page-cards';
import { arrowStep } from '../../src/lib/reader/keyboard-nav';
import { canTrackResume, firstVisibleAyah } from '../../src/lib/reader/resume-observer';

describe('groupAyahsByPage', () => {
  it('groups ayahs by page, ordered by page and by ayah number', () => {
    const groups = groupAyahsByPage([
      { page: 2, n: 4 },
      { page: 1, n: 3 },
      { page: 1, n: 1 },
      { page: 2, n: 5 },
    ]);
    expect(groups.map((g) => g.page)).toEqual([1, 2]);
    expect(groups[0].items.map((i) => i.n)).toEqual([1, 3]);
    expect(groups[1].items.map((i) => i.n)).toEqual([4, 5]);
  });

  it('drops ayahs without a usable page number', () => {
    const groups = groupAyahsByPage([
      { page: Number.NaN, n: 1 },
      { page: 1.5, n: 2 },
      { page: 3, n: 3 },
    ]);
    expect(groups).toHaveLength(1);
    expect(groups[0].items.map((i) => i.n)).toEqual([3]);
  });

  it('returns nothing for an empty page', () => {
    expect(groupAyahsByPage([])).toEqual([]);
  });
});

describe('arrowStep', () => {
  it('pages forward with the left arrow in an RTL document', () => {
    expect(arrowStep('ArrowLeft', 'ar')).toBe(1);
    expect(arrowStep('ArrowRight', 'ar')).toBe(-1);
  });

  it('pages forward with the right arrow in an LTR document', () => {
    expect(arrowStep('ArrowRight', 'en')).toBe(1);
    expect(arrowStep('ArrowLeft', 'en')).toBe(-1);
  });

  it('ignores every other key', () => {
    expect(arrowStep('ArrowUp', 'ar')).toBe(0);
    expect(arrowStep('a', 'en')).toBe(0);
    expect(arrowStep('Enter', 'ar')).toBe(0);
  });
});

describe('canTrackResume', () => {
  it('needs a surah and at least one ayah', () => {
    expect(canTrackResume(2, 7)).toBe(true);
    expect(canTrackResume(2, 0)).toBe(false);
    expect(canTrackResume(Number.NaN, 7)).toBe(false);
    expect(canTrackResume(2.5, 7)).toBe(false);
  });
});

describe('firstVisibleAyah', () => {
  const blocks = [{ n: 1 }, { n: 2 }, { n: 3 }];

  it('follows the first ayah of the list that is on screen', () => {
    expect(firstVisibleAyah(blocks, new Set([2, 3]))).toBe(2);
    expect(firstVisibleAyah(blocks, new Set([3]))).toBe(3);
  });

  it('has no resume point when nothing is visible', () => {
    expect(firstVisibleAyah(blocks, new Set())).toBeNull();
  });

  it('has no resume point when the ayah number is unusable', () => {
    expect(firstVisibleAyah([{ n: Number.NaN }], new Set([Number.NaN]))).toBeNull();
  });
});
