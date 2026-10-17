import { describe, it, expect } from 'vitest';
import { statSync, readFileSync } from 'node:fs';

const files = ['logo-64.png', 'favicon-32.png', 'favicon-16.png', 'apple-touch-icon-180.png', 'og-base.png'];
const PNG_SIGNATURE = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
describe('brand assets exist', () => {
  it.each(files)('public/%s', (f) => {
    const url = new URL(`../../public/${f}`, import.meta.url);
    const s = statSync(url);
    expect(s.size).toBeGreaterThan(300);
    expect([...readFileSync(url).subarray(0, 8)]).toEqual(PNG_SIGNATURE);
  });
});
