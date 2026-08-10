import { defineConfig } from "@playwright/test"

// Phase 8 of the frontend migration — Cypress 12 → Playwright.
// E2E specs live under `test/e2e/` so they sit next to the
// Minitest suite (this app uses Minitest, not RSpec). `data-test`
// is the testId attribute. `webServer` boots Puma so
// `pnpm test:e2e:run` works the same way locally and in CI.
// Keep the e2e port inside this app's own block (dev 8240, PG 8241,
// Redis 8242): `reuseExistingServer` below attaches to whatever already
// listens here, so a port another app owns runs the suite against that app.
const port = Number(process.env.PORT ?? 8250)
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://localhost:${port}`

export default defineConfig({
  testDir: "./test/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "blob" : "html",
  timeout: 60 * 1000,
  expect: { timeout: 10 * 1000 },
  globalTimeout: 60 * 60 * 1000,
  use: {
    baseURL,
    trace: "on-first-retry",
    testIdAttribute: "data-test",
  },
  webServer: {
    command: "pnpm test:e2e:startserver",
    // Puma reads PORT (config/puma.rb) and the islands build ApiBasePath
    // from DOMAIN, so both have to match the port we poll — otherwise the
    // server comes up somewhere else and the API calls leave the host.
    env: {
      PORT: String(port),
      DOMAIN: process.env.DOMAIN ?? `localhost:${port}`,
    },
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe",
    timeout: 120_000,
  },
})
