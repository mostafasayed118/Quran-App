import { test, expect } from '@playwright/test';

test('assetlinks.json is served from the built site', async ({ request }) => {
  const res = await request.get('/.well-known/assetlinks.json');
  expect(res.status()).toBe(200);
  expect(res.headers()['content-type']).toContain('json');
  const body = (await res.json()) as Array<{
    relation: string[];
    target: { namespace: string; package_name: string; sha256_cert_fingerprints: string[] };
  }>;
  expect(body[0].target.package_name).toBe('com.mostafasayed.quranyahdi');
  expect(body[0].relation).toContain('delegate_permission/common.handle_all_urls');
  expect(body[0].target.sha256_cert_fingerprints.length).toBeGreaterThan(0);
});
