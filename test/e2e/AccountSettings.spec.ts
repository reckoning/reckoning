import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The account's own settings: six sections, each saving what it shows, the
// way the six server-rendered partials each carried their own submit.
test.describe("Account settings", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    // The scenario writes the account past its validations, because they
    // cannot all be met before its first user exists. Saving from this
    // screen validates like any other account does, so it needs the plan a
    // real one carries.
    await appEval(`Account.find_by(name: "Enterprise").update_columns(plan: "free")`)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("saves the account's name on its own", async ({ page }) => {
    await page.goto("/account")

    await expect(page.getByTestId("name")).toHaveValue("Enterprise")

    await page.getByTestId("name").fill("Enterprise-D")
    await page.getByTestId("submit-basic").click()

    await expect.poll(async () => appEval(`Account.first.name`)).toBe("Enterprise-D")
  })

  // The section is the hash, so a link into one of them keeps working.
  test("opens the section the url names and switches by the side nav", async ({ page }) => {
    await page.goto("/account#banking")

    await expect(page.getByTestId("section-banking")).toBeVisible()

    await page.getByTestId("section-link-taxes").click()

    await expect(page).toHaveURL(/#taxes$/)
    await expect(page.getByTestId("section-taxes")).toBeVisible()
    await expect(page.getByTestId("section-banking")).toHaveCount(0)
  })

  // Both office fields are what the deductible share is worked out from, and
  // a home-office expense deducts nothing until they are there.
  test("saves the office space the deduction is worked out from", async ({ page }) => {
    await page.goto("/account#address")

    await page.getByTestId("office-space").fill("100")
    await page.getByTestId("deductible-office-space").fill("25")
    await page.getByTestId("submit-address").click()

    await expect.poll(async () => appEval(`Account.first.deductible_office_percent`)).toBe(25)
  })

  test("saves the signature the invoice mails carry", async ({ page }) => {
    await page.goto("/account#mailing")

    await page.getByTestId("signature").fill("Live long and prosper")
    await page.getByTestId("submit-mailing").click()

    await expect.poll(async () => appEval(`Account.first.signature`)).toBe("Live long and prosper")
  })

  test("forwards the old rails path to the spa", async ({ page }) => {
    await page.goto("/account/edit")

    await expect(page).toHaveURL(/\/account$/)
    await expect(page.getByTestId("section-basic")).toBeVisible()
  })

  test("is reachable from the user menu", async ({ page }) => {
    await page.goto("/")

    await page.getByTestId("user-menu").click()
    await page.getByTestId("nav-account").click()

    await expect(page).toHaveURL(/\/account$/)
    await expect(page.getByTestId("section-basic")).toBeVisible()
  })
})
