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
// This machine's debug cert, kept so debug builds verify during device testing.
const DEBUG_FP =
  'B9:95:23:DA:5E:E0:0C:8B:7D:0E:4F:6E:B8:3B:EB:ED:A2:97:3B:59:2D:9E:8C:E9:4A:0A:5B:34:66:F5:97:03';

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

  it('pins the release keystore fingerprint', () => {
    expect(statements[0].target.sha256_cert_fingerprints).toContain(RELEASE_FP);
  });

  it('keeps the local debug fingerprint for device testing', () => {
    expect(statements[0].target.sha256_cert_fingerprints).toContain(DEBUG_FP);
  });
});
