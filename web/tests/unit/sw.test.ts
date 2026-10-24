import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../../public/sw.js', import.meta.url), 'utf8');

describe('service worker contract', () => {
  it('pins the cache version', () => {
    expect(source).toContain("const CACHE_VERSION = 'qy-v1'");
  });

  it('precaches both offline pages', () => {
    expect(source).toContain("'/offline/'");
    expect(source).toContain("'/en/offline/'");
  });

  it('bypasses the worker, well-known files and the sitemap', () => {
    for (const token of ["'/sw.js'", "'/.well-known/'", "'/sitemap.xml'"]) {
      expect(source).toContain(token);
    }
  });

  it('bypasses range requests so audio keeps streaming natively', () => {
    expect(source).toContain("request.headers.has('range')");
  });
});
