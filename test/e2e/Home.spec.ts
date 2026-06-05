import { test, expect } from "./support/commands"
import { app } from "./support/on-rails"

test.describe("Home", () => {
  test.beforeEach(async () => {
    await app("clean")
  })

  test("home page loads and shows the brand", async ({ page }) => {
    await page.goto("/")
    await expect(page.locator("body")).toContainText("Reckoning")
  })
})
