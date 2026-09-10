import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

test.describe("Home", () => {
  test.beforeEach(async () => {
    await app("clean")
  })

  test("shows the welcome page to a visitor", async ({ page }) => {
    await page.goto("/")

    await expect(page.locator("body")).toContainText("Reckoning")
    // The server-rendered welcome page, not the SPA shell behind it.
    await expect(page.locator("#spa")).toHaveCount(0)
  })

  // The welcome page is for visitors; anyone with a session belongs in the app.
  test("sends a signed-in visitor into the spa", async ({ page }) => {
    await appScenario("signed_out_user")

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-title")).toBeVisible()

    await page.goto("/")

    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)
  })
})
