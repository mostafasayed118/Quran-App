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

function tokenValue(theme: 'day' | 'night', name: string): string {
  const block = theme === 'day'
    ? css.match(/\[data-theme=['"]day['"]\][^}]*}/)?.[0] ?? ''
    : css.match(/\[data-theme=['"]night['"]\][^}]*}/)?.[0] ?? '';
  const m = block.match(new RegExp(`${name}\\s*:\\s*([^;]+);`));
  if (!m) throw new Error(`token ${name} missing in ${theme}`);
  return m[1].trim();
}
function rgba(value: string): { rgb: [number, number, number]; a: number } {
  const m = value.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)$/);
  if (!m) throw new Error(`not an rgba() color: ${value}`);
  return { rgb: [+m[1], +m[2], +m[3]], a: m[4] === undefined ? 1 : parseFloat(m[4]) };
}
function compositeOver(fg: string, bgHex: string): string {
  const { rgb, a } = rgba(fg);
  const bg = hexToRgb(bgHex);
  const out = rgb.map((c, i) => Math.round(c * a + bg[i] * (1 - a)));
  return '#' + out.map((v) => v.toString(16).padStart(2, '0')).join('');
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

const nightGradientFirstStop = css.match(/linear-gradient\(180deg,\s*(#[0-9a-fA-F]{6})/)?.[1];
describe('WCAG AA contrast (muted-strong chrome text, a11y ruling)', () => {
  it('day: --muted-strong composited over --bg-solid', () => {
    const bg = token('day', '--bg-solid');
    expect(contrast(compositeOver(tokenValue('day', '--muted-strong'), bg), bg)).toBeGreaterThanOrEqual(AA);
  });
  it('night: --muted-strong composited over the night gradient first stop', () => {
    if (!nightGradientFirstStop) throw new Error('night gradient first stop missing in tokens.css');
    expect(
      contrast(compositeOver(tokenValue('night', '--muted-strong'), nightGradientFirstStop), nightGradientFirstStop),
    ).toBeGreaterThanOrEqual(AA);
  });
});
