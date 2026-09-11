import { test, expect } from "./support/commands"
import { app } from "./support/on-rails"

test.describe("Legal pages", () => {
  test.beforeEach(async () => {
    await app("clean")
  })

  // They answered 200 with an empty body for years. The paths stay; the
  // documents are new.
  test("serves the three documents on the paths they have always had", async ({ page }) => {
    for (const [path, heading] of [
      ["/impressum", "Impressum"],
      ["/privacy", "Datenschutzerklärung"],
      ["/terms", "Allgemeine Geschäftsbedingungen"],
    ]) {
      await page.goto(path)

      await expect(page.getByRole("heading", { level: 1 })).toContainText(heading)
    }
  })

  // Nothing linked them before, which is why nobody noticed they were empty.
  test("reaches them from the footer", async ({ page }) => {
    await page.goto("/")

    await page.getByTestId("nav-privacy").click()

    await expect(page).toHaveURL(/\/privacy$/)
    await expect(page.getByTestId("legal-privacy")).toBeVisible()
  })
})
