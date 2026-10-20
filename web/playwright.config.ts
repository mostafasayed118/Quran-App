import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  // A local run must never measure a stale server left on port 4321, and it does
  // not retry: a failing spec is signal, not flake.
  timeout: 60_000,
  retries: 0,
  use: { baseURL: 'http://localhost:4321' },
  webServer: {
    command: 'npm run build && npm run preview -- --port 4321',
    port: 4321,
    reuseExistingServer: false,
  },
});
