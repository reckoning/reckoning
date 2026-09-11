import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

test.describe("Signup", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("plans")
  })

  test("creates an account and sends the visitor to sign in", async ({ page }) => {
    await page.goto("/signup")

    await page.getByTestId("name").fill("Vulcan Science Academy")
    await page.getByTestId("email").fill("t.pol@vulcan.gov")
    await page.getByTestId("password").fill("logic-is-the-beginning")
    await page.getByTestId("password-confirmation").fill("logic-is-the-beginning")
    await page.getByTestId("vat-id").fill("VU-1701")
    await page.getByTestId("subdomain").fill("vulcan")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/login$/)

    const account = await appEval(
      `Account.find_by(name: "Vulcan Science Academy").then { |a| [a.plan, a.vat_id, a.subdomain, a.users.count] }`,
    )

    expect(account).toEqual(["basic", "VU-1701", "vulcan", 1])
  })

  // The refusal a visitor is most likely to hit lands on the field it is about.
  test("says which field the server refused", async ({ page }) => {
    await appEval(`Account.new(name: "Vulcan", plan: "basic", subdomain: "vulcan").save(validate: false)`)

    await page.goto("/signup")

    await page.getByTestId("name").fill("Vulcan Science Academy")
    await page.getByTestId("email").fill("archer@earth.gov")
    await page.getByTestId("password").fill("logic-is-the-beginning")
    await page.getByTestId("password-confirmation").fill("logic-is-the-beginning")
    await page.getByTestId("subdomain").fill("vulcan")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("subdomain-error")).toBeVisible()
  })

  // The pricing table hands the plan over in the query.
  test("starts on the plan the pricing table sent", async ({ page }) => {
    await page.goto("/signup?plan=plus")

    await expect(page.getByTestId("plan")).toHaveValue("plus")
  })
})
