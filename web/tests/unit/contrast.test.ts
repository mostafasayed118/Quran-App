import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16)) as [number, number, number];
}
function luminance(hex: string): number {
  const [r, g, b] = hexToRgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
function contrast(a: string, b: string): number {
  const [l1, l2] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (l1 + 0.05) / (l2 + 0.05);
}

const css = readFileSync(new URL('../../src/styles/tokens.css', import.meta.url), 'utf8');
function token(theme: 'day' | 'night', name: string): string {
  const block = theme === 'day'
    ? css.match(/\[data-theme=['"]day['"]\][^}]*}/)?.[0] ?? ''
    : css.match(/\[data-theme=['"]night['"]\][^}]*}/)?.[0] ?? '';
  const m = block.match(new RegExp(`${name}\\s*:\\s*(#[0-9a-fA-F]{6})`));
  if (!m) throw new Error(`token ${name} missing in ${theme}`);
  return m[1];
}

const AA = 4.5;
describe('WCAG AA contrast (token pairs, spec §3.9)', () => {
  it.each([
    ['day', '--ink', '--bg-solid'],
    ['day', '--gold-ink', '--bg-solid'],
    ['day', '--accent', '--bg-solid'],
    ['day', '--btn-ink', '--btn-bg'],
    ['night', '--ink', '--surface'],
    ['night', '--gold-ink', '--surface'],
    ['night', '--accent', '--surface'],
    ['night', '--btn-ink', '--btn-bg'],
  ] as const)('%s: %s on %s', (theme, fg, bg) => {
    expect(contrast(token(theme, fg), token(theme, bg))).toBeGreaterThanOrEqual(AA);
  });
});
