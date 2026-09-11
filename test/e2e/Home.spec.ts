import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

test.describe("Home", () => {
  test.beforeEach(async () => {
    await app("clean")
  })

  test("shows the welcome page to a visitor", async ({ page }) => {
    await page.goto("/")

    await expect(page.getByRole("heading", { level: 1 })).toContainText(
      "Rechnungen schreiben einfach gemacht.",
    )
    await expect(page.getByTestId("screenshot")).toHaveCount(3)
    // The landing bar, which only the public screens carry.
    await expect(page.getByTestId("nav-sign-in")).toBeVisible()
    await expect(page.getByTestId("main-nav")).toHaveCount(0)
  })

  // The screenshots are thumbnails; the page shows the full one over them.
  test("opens a screenshot", async ({ page }) => {
    await page.goto("/")

    await page.getByTestId("screenshot").first().click()
    await expect(page.getByTestId("screenshot-modal")).toBeVisible()

    await page.getByTestId("close-screenshot").click()
    await expect(page.getByTestId("screenshot-modal")).toHaveCount(0)
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
