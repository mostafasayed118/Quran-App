import { describe, it, expect } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'node:fs';

const DIR = new URL('../../public/og/surah/', import.meta.url);
const PNG_SIGNATURE = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const expected = Array.from({ length: 114 }, (_, i) => `${i + 1}.png`);

describe('per-surah OG assets exist', () => {
  it('has exactly 114 files named 1.png … 114.png', () => {
    const actual = readdirSync(DIR).sort((a, b) => Number.parseInt(a, 10) - Number.parseInt(b, 10));
    expect(actual).toEqual(expected);
  });

  it('every file is a PNG of at least 2 KB', () => {
    for (const f of expected) {
      const url = new URL(f, DIR);
      const s = statSync(url);
      expect(s.size).toBeGreaterThanOrEqual(2048);
      expect([...readFileSync(url).subarray(0, 8)]).toEqual(PNG_SIGNATURE);
    }
  });

  it('total size stays under 8 MB', () => {
    const total = expected.reduce((sum, f) => sum + statSync(new URL(f, DIR)).size, 0);
    expect(total).toBeLessThanOrEqual(8 * 1024 * 1024);
  });
});
