import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B3: the customer screens moved into the SPA and the ERB form is gone.
test.describe("Customers", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      Customer.create!(account: account, name: "Starfleet", contact_information: {"email" => "ops@star.fleet"})
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("edits a customer from the list", async ({ page }) => {
    await page.goto("/app/customers")

    await page.getByText("Starfleet").click()

    await expect(page.getByTestId("customer-title")).toHaveText("Starfleet")
    await expect(page.getByTestId("name")).toHaveValue("Starfleet")

    await page.getByTestId("name").fill("Starfleet Command")
    await page.getByTestId("submit").click()

    await expect(page.getByText("Kunde gespeichert.")).toBeVisible()

    const name = await appEval(`Customer.find_by(name: "Starfleet Command")&.name`)
    expect(name).toBe("Starfleet Command")
  })

  test("keeps the three tabs the ERB form had", async ({ page }) => {
    const id = (await appEval(`Customer.find_by(name: "Starfleet").id`)) as string

    await page.goto(`/app/customers/${id}/edit`)

    await expect(page.getByTestId("name")).toBeVisible()

    await page.getByTestId("tab-email").click()
    await expect(page.getByTestId("email-template")).toBeVisible()

    await page.getByTestId("tab-offer").click()
    await expect(page.getByTestId("offer-disclaimer")).toBeVisible()
  })

  test("refuses to save without a name", async ({ page }) => {
    const id = (await appEval(`Customer.find_by(name: "Starfleet").id`)) as string

    await page.goto(`/app/customers/${id}/edit`)
    await page.getByTestId("name").fill("")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("name-error")).toBeVisible()
    expect(await appEval(`Customer.find_by(name: "Starfleet").present?`)).toBe(true)
  })

  // The project list still links to the old path, and so do bookmarks.
  test("forwards the old rails path to the spa", async ({ page }) => {
    const id = (await appEval(`Customer.find_by(name: "Starfleet").id`)) as string

    await page.goto(`/customers/${id}/edit`)

    await expect(page).toHaveURL(new RegExp(`/app/customers/${id}/edit$`))
    await expect(page.getByTestId("customer-title")).toHaveText("Starfleet")
  })
})
