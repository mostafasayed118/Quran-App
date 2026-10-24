import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../../public/_headers', import.meta.url), 'utf8');

function parseBlocks(text: string): Map<string, Map<string, string>> {
  const blocks = new Map<string, Map<string, string>>();
  let current: Map<string, string> | null = null;
  for (const line of text.split(/\r?\n/)) {
    if (line.trim() === '' || line.trim().startsWith('#')) continue;
    if (!/^\s/.test(line)) {
      current = new Map();
      blocks.set(line.trim(), current);
      continue;
    }
    const colon = line.indexOf(':');
    if (!current || colon < 0) continue;
    current.set(line.slice(0, colon).trim(), line.slice(colon + 1).trim());
  }
  return blocks;
}

const blocks = parseBlocks(source);

describe('_headers cache-control', () => {
  it('declares the root, hashed asset and font path blocks', () => {
    expect([...blocks.keys()]).toEqual(['/*', '/_astro/*', '/fonts/*', '/data/*', '/og/*']);
  });

  it('marks content-hashed /_astro assets immutable for a year', () => {
    expect(blocks.get('/_astro/*')?.get('Cache-Control')).toBe(
      'public, max-age=31536000, immutable',
    );
  });

  it('bounds the cache for unhashed font filenames', () => {
    expect(blocks.get('/fonts/*')?.get('Cache-Control')).toBe('public, max-age=604800');
  });

  it('keeps the root security headers intact', () => {
    const root = blocks.get('/*');
    expect(root?.get('X-Content-Type-Options')).toBe('nosniff');
    expect(root?.get('Content-Security-Policy')).toContain("default-src 'self'");
  });
});
