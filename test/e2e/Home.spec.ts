import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

test.describe("Home", () => {
  test.beforeEach(async () => {
    await app("clean")
  })

  test("home page loads and shows the brand", async ({ page }) => {
    await page.goto("/")
    await expect(page.locator("body")).toContainText("Reckoning")
  })

  // The welcome page is for visitors; anyone with a session belongs in the app.
  test("sends a signed-in visitor into the spa", async ({ page }) => {
    await appScenario("signed_out_user")

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-title")).toBeVisible()

    await page.goto("/")

    await expect(page).toHaveURL(/\/app\/?$/)
  })
})
