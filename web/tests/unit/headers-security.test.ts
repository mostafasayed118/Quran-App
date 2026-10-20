import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

/**
 * The security half of `public/_headers` (the cache half is covered by
 * headers.test.ts). Every assertion here is a contract the shipped site
 * depends on, so a drift is a regression, not a style change.
 */
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

const root = parseBlocks(source).get('/*');
const csp = root?.get('Content-Security-Policy') ?? '';

/** The value of one CSP directive, e.g. `script-src`. */
function directive(name: string): string {
  const hit = new RegExp(`(?:^|;)\\s*${name}\\s+([^;]*)`).exec(csp);
  return hit ? hit[1].trim() : '';
}

describe('_headers security policy', () => {
  it('keeps the root block', () => {
    expect(root).toBeDefined();
  });

  it('locks the default source to the site itself', () => {
    expect(directive('default-src')).toBe("'self'");
  });

  it('allows scripts from the site only, by hash for the inline ones', () => {
    const scriptSrc = directive('script-src');
    expect(scriptSrc).toContain("'self'");
    expect(scriptSrc).not.toContain("'unsafe-inline'");
    expect(scriptSrc).not.toContain("'unsafe-eval'");
    // The four inline scripts are allowed by their exact bytes.
    expect(scriptSrc.match(/'sha256-[^']+'/g)).toHaveLength(4);
  });

  it('allows styles from the site only (the CSS ships as a hashed file)', () => {
    const styleSrc = directive('style-src');
    expect(styleSrc).toBe("'self'");
    expect(styleSrc).not.toContain("'unsafe-inline'");
  });

  it('locks the object, base and form sources', () => {
    expect(directive('object-src')).toBe("'none'");
    expect(directive('base-uri')).toBe("'self'");
    expect(directive('form-action')).toBe("'self'");
  });

  it('forbids framing and upgrades insecure requests', () => {
    expect(directive('frame-ancestors')).toBe("'none'");
    expect(csp).toContain('upgrade-insecure-requests');
  });

  // NOTE: `require-trusted-types-for 'script'` is deliberately absent: Astro's
  // client router assigns innerHTML and calls DOMParser.parseFromString, so the
  // directive blocks every SPA navigation in Chrome. The site's own code has no
  // HTML sink (no set:html, no innerHTML, no eval).

  it('keeps the transport and framing headers', () => {
    expect(root?.get('X-Content-Type-Options')).toBe('nosniff');
    expect(root?.get('X-Frame-Options')).toBe('DENY');
    expect(root?.get('Referrer-Policy')).toBe('strict-origin-when-cross-origin');
    expect(root?.get('Strict-Transport-Security')).toBe('max-age=31536000');
  });

  it('keeps the permissions policy: no camera, no microphone, geolocation for us', () => {
    const policy = root?.get('Permissions-Policy') ?? '';
    expect(policy).toContain('camera=()');
    expect(policy).toContain('microphone=()');
    expect(policy).toContain('geolocation=(self)');
  });
});
