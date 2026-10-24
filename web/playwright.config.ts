import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  // A local run must never measure a stale server left on port 4321, and it does
  // not retry: a failing spec is signal, not flake.
  timeout: 60_000,
  retries: 0,
  use: {
    baseURL: 'http://localhost:4321',
    // Keep the service worker out of the normal specs so app-level network-failure
    // tests still exercise the real fetch path; the offline spec opts in explicitly.
    serviceWorkers: 'block',
    // Keep the failure evidence without changing the no-retry policy: there is
    // no first retry to hook, so retain the trace and screenshot of the failure.
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'npm run build && npm run preview -- --port 4321',
    port: 4321,
    reuseExistingServer: false,
  },
});
