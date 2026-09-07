import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B6, first half: the invoice list. The detail page and the position
// editor are still server-rendered.
test.describe("Invoices", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    // `before_save :set_value` derives the value from the positions, so the
    // amounts go in past the callback.
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.create!(account: account, name: "Starfleet")
      project = customer.projects.create!(name: "Narendra 3", rate: 90)
      paid = account.invoices.create!(customer: customer, project: project, date: Date.new(2026, 3, 1), ref: 1)
      paid.update_columns(value: 100, workflow_state: "paid")
      open_one = account.invoices.create!(customer: customer, project: project, date: Date.new(2026, 4, 1), ref: 2)
      open_one.update_columns(value: 250, workflow_state: "created")
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("lists the invoices with what they add up to", async ({ page }) => {
    await page.goto("/app/invoices")

    const table = page.getByTestId("invoices")
    await expect(table).toContainText("00001")
    await expect(table).toContainText("00002")
    await expect(table).toContainText("Starfleet")

    // 100 + 250, from the summary endpoint rather than from the page.
    await expect(page.getByTestId("summary-value")).toContainText("350")
  })

  test("filters, and the total follows the filter", async ({ page }) => {
    await page.goto("/app/invoices")

    await page.getByTestId("filter-state").click()
    await page.getByTestId("filter-state-paid").click()

    await expect(page.getByTestId("invoices")).not.toContainText("00002")
    await expect(page.getByTestId("summary-value")).toContainText("100")
    await expect(page).toHaveURL(/state=paid/)
  })

  test("sorts by a column and says which way", async ({ page }) => {
    await page.goto("/app/invoices")

    await page.getByTestId("sort-value").click()

    await expect(page).toHaveURL(/sort=value&direction=desc/)

    // The list is a panel of rows again, not a table.
    const firstRow = page.locator('[data-test^="invoice-"]').first()
    await expect(firstRow).toContainText("00002")
  })

  // The navigation links `invoices_path`, and so do the redirects after
  // charging or paying an invoice.
  test("forwards the old rails path with its query", async ({ page }) => {
    await page.goto("/invoices?state=paid")

    await expect(page).toHaveURL(/\/app\/invoices\?state=paid$/)
    await expect(page.getByTestId("invoices")).toContainText("00001")
  })
})
