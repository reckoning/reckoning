import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B7, first half: the offer list. The detail page and the position
// editor are still server-rendered.
test.describe("Offers", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    // `before_save :set_value` derives the value from the positions, so the
    // amounts go in past the callback.
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.create!(account: account, name: "Starfleet")
      project = customer.projects.create!(name: "Narendra 3", rate: 90)
      accepted = account.offers.create!(customer: customer, project: project, date: Date.new(2026, 3, 1), ref: 1)
      accepted.update_columns(value: 100, aasm_state: "accepted")
      open_one = account.offers.create!(customer: customer, project: project, date: Date.new(2026, 4, 1), ref: 2)
      open_one.update_columns(value: 250, aasm_state: "bided")
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("lists the offers with what they add up to", async ({ page }) => {
    await page.goto("/offers")

    const table = page.getByTestId("offers")
    await expect(table).toContainText("00001")
    await expect(table).toContainText("00002")
    await expect(table).toContainText("Starfleet")
    await expect(table).toContainText("Narendra 3")

    // 100 + 250, from the summary endpoint rather than from the page.
    await expect(page.getByTestId("summary-value")).toContainText("350")
  })

  test("filters, and the total follows the filter", async ({ page }) => {
    await page.goto("/offers")

    await page.getByTestId("filter-state").click()
    await page.getByTestId("filter-state-accepted").click()

    await expect(page.getByTestId("offers")).not.toContainText("00002")
    await expect(page.getByTestId("summary-value")).toContainText("100")
    await expect(page).toHaveURL(/state=accepted/)
  })

  test("sorts by a column and says which way", async ({ page }) => {
    await page.goto("/offers")

    await page.getByTestId("sort-value").click()

    await expect(page).toHaveURL(/sort=value&direction=desc/)

    // The list is a panel of rows again, not a table.
    const firstRow = page.locator('[data-test^="offer-"]').first()
    await expect(firstRow).toContainText("00002")
  })

  // The main navigation links `offers_path`, and so do the redirects after
  // creating or updating an offer.
  test("answers a page load on the list, query and all", async ({ page }) => {
    await page.goto("/offers?state=accepted")

    await expect(page).toHaveURL(/\/offers\?state=accepted$/)
    await expect(page.getByTestId("offers")).toContainText("00001")
  })
})
