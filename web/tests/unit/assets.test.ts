import { describe, it, expect } from 'vitest';
import { statSync } from 'node:fs';

const files = ['logo-64.png', 'favicon-32.png', 'favicon-16.png', 'apple-touch-icon-180.png', 'og-base.png'];
describe('brand assets exist', () => {
  it.each(files)('public/%s', (f) => {
    const s = statSync(new URL(`../../public/${f}`, import.meta.url));
    expect(s.size).toBeGreaterThan(1000);
  });
});
