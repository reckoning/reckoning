import { defineConfig } from "@playwright/test"

// Phase 8 of the frontend migration — Cypress 12 → Playwright.
// E2E specs live under `test/e2e/` so they sit next to the
// Minitest suite (this app uses Minitest, not RSpec). `data-test`
// is the testId attribute. `webServer` boots Puma so
// `pnpm test:e2e:run` works the same way locally and in CI.
const port = Number(process.env.PORT ?? 8270)
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
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe",
    timeout: 120_000,
  },
})
