import { defineConfig } from "@playwright/test"

// Phase 8 of the frontend migration — replaces Cypress 12 (whose
// transitive deps accounted for the last 11 dev-only npm vulns).
// One actual spec ports across; the rest of the Cypress `commands.js`
// surface was cargo-culted Star Citizen helpers from another project
// that this app never used.
//
// CI runs against a Rails server started by the workflow; locally
// `webServer` auto-boots Puma on PORT 8270 (matches the Cypress
// setup so DNS / hosts entries that pointed at reckoning.test
// keep working).
const port = Number(process.env.PORT ?? 8270)
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://localhost:${port}`

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  webServer: process.env.CI
    ? undefined
    : {
        command: "bundle exec puma -C config/puma.rb",
        url: baseURL,
        reuseExistingServer: true,
        timeout: 120_000,
        env: { PORT: String(port) },
      },
})
