import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../../public/.well-known/assetlinks.json', import.meta.url), 'utf8');

type Statement = {
  relation: string[];
  target: { namespace: string; package_name: string; sha256_cert_fingerprints: string[] };
};
const statements = JSON.parse(source) as Statement[];

// Owner-provided release cert (keytool, 2026-10-18). Verified at build time:
// apksigner verify --print-certs on the signed release APK must print this digest.
const RELEASE_FP =
  'D2:1E:83:DC:9F:B5:9F:6D:61:5A:A3:FF:A7:70:22:13:61:64:6A:8F:2B:70:50:FF:BE:24:DA:CC:1D:98:CB:DA';

describe('assetlinks.json (Android App Links)', () => {
  it('declares handle_all_urls for the app package', () => {
    expect(statements).toHaveLength(1);
    expect(statements[0].relation).toContain('delegate_permission/common.handle_all_urls');
    expect(statements[0].target.namespace).toBe('android_app');
    expect(statements[0].target.package_name).toBe('com.mostafasayed.quranyahdi');
  });

  it('lists only well-formed SHA-256 fingerprints', () => {
    const fps = statements[0].target.sha256_cert_fingerprints;
    expect(fps.length).toBeGreaterThan(0);
    for (const fp of fps) expect(fp).toMatch(/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/);
  });

  it('pins the release fingerprint only (debug FP removed by owner decision 2026-10-19)', () => {
    expect(statements[0].target.sha256_cert_fingerprints).toEqual([RELEASE_FP]);
  });
});
