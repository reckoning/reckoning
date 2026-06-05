import { test, expect } from "@playwright/test"

// Ported from the Cypress `Home.cy.js` spec — the only meaningful
// e2e Reckoning had before Phase 8. Confirms the marketing-page
// landing route boots and renders the app name.
test("home page loads and shows the brand", async ({ page }) => {
  await page.goto("/")
  await expect(page.locator("body")).toContainText("Reckoning")
})
